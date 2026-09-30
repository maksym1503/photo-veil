import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UIKit
import Vision

struct BlurRenderer {
    static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func normalizedImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let oriented = CIImage(cgImage: cgImage).oriented(forExifOrientation: exifOrientation(image.imageOrientation))
        guard let result = context.createCGImage(oriented, from: oriented.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    static func render(_ image: UIImage, regions: [CGRect], strength: BlurStrength, personMask: CIImage? = nil) -> UIImage? {
        guard let source = image.cgImage else { return nil }
        let original = CIImage(cgImage: source)
        let extent = original.extent
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = original.clampedToExtent()
        blur.radius = strength.radius
        guard let softened = blur.outputImage?.cropped(to: extent) else { return nil }

        var mask: CIImage?
        if let personMask {
            mask = personMask
        } else if !regions.isEmpty {
            mask = regionMask(size: CGSize(width: extent.width, height: extent.height), regions: regions)
        }
        guard let mask else { return image }
        let feather = CIFilter.gaussianBlur()
        feather.inputImage = mask.clampedToExtent()
        feather.radius = 3
        let blendedMask = feather.outputImage?.cropped(to: extent) ?? mask
        let blend = CIFilter.blendWithMask()
        blend.inputImage = softened
        blend.backgroundImage = original
        blend.maskImage = blendedMask
        guard let output = blend.outputImage?.cropped(to: extent), let cg = context.createCGImage(output, from: extent) else { return nil }
        return UIImage(cgImage: cg, scale: image.scale, orientation: .up)
    }

    static func renderBackground(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage) {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .accurate
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        try VNImageRequestHandler(cgImage: cg).perform([request])
        guard let buffer = request.results?.first?.pixelBuffer else { throw BlurError.noSubject }
        let mask = CIImage(cvPixelBuffer: buffer)
            .transformed(by: CGAffineTransform(scaleX: CGFloat(cg.width) / CGFloat(CVPixelBufferGetWidth(buffer)), y: CGFloat(cg.height) / CGFloat(CVPixelBufferGetHeight(buffer))))
        guard let rendered = render(image, regions: [], strength: strength, personMask: mask) else { throw BlurError.unavailable }
        return (rendered, mask)
    }

    static func detectFaces(in image: UIImage) async throws -> [CGRect] {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let request = VNDetectFaceRectanglesRequest()
        try VNImageRequestHandler(cgImage: cg).perform([request])
        return (request.results ?? []).map { expandedFace(ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox)) }
    }

    static func detectPlateSuggestions(in image: UIImage) async throws -> [CGRect] {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: cg).perform([request])
        return (request.results ?? []).compactMap { observation in
            let rect = observation.boundingBox
            let ratio = rect.width / max(rect.height, 0.001)
            guard ratio > 1.7, ratio < 7.5, rect.width > 0.055 else { return nil }
            return ImageGeometryMapper.topLeftRect(fromVision: rect).insetBy(dx: -rect.width * 0.12, dy: -rect.height * 0.28)
        }
    }

    private static func expandedFace(_ rect: CGRect) -> CGRect {
        let expanded = rect.insetBy(dx: -rect.width * 0.22, dy: -rect.height * 0.25)
        let minX = max(0, expanded.minX), minY = max(0, expanded.minY)
        let maxX = min(1, expanded.maxX), maxY = min(1, expanded.maxY)
        return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
    }

    private static func regionMask(size: CGSize, regions: [CGRect]) -> CIImage? {
        let width = Int(size.width), height = Int(size.height)
        guard width > 0, height > 0, let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(origin: .zero, size: size))
        context.setFillColor(gray: 1, alpha: 1)
        context.saveGState()
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        for rect in regions {
            let pixelRect = CGRect(x: rect.minX * size.width, y: rect.minY * size.height, width: rect.width * size.width, height: rect.height * size.height)
            context.addEllipse(in: pixelRect.insetBy(dx: -pixelRect.width * 0.12, dy: -pixelRect.height * 0.12))
            context.fillPath()
        }
        context.restoreGState()
        guard let cg = context.makeImage() else { return nil }
        return CIImage(cgImage: cg)
    }

    private static func exifOrientation(_ orientation: UIImage.Orientation) -> Int32 {
        switch orientation {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}

enum BlurStrength: String, CaseIterable, Identifiable {
    case low = "Low", medium = "Medium", strong = "Strong"
    var id: String { rawValue }
    var radius: Float { switch self { case .low: 12; case .medium: 24; case .strong: 38 } }
}

enum BlurError: Error { case unavailable, noSubject }
