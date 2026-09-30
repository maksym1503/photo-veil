import CoreImage
import ImageIO
import UIKit
import Vision

struct BlurRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func normalizedImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let oriented = CIImage(cgImage: cgImage).oriented(forExifOrientation: exifOrientation(image.imageOrientation))
        guard let result = context.createCGImage(oriented, from: oriented.extent) else { return nil }
        return UIImage(cgImage: result, scale: 1, orientation: .up)
    }

    static func previewImage(_ image: UIImage, maxDimension: Int = 1800) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: 0.98),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: thumbnail, scale: 1, orientation: .up)
    }

    static func render(_ image: UIImage, regions: [BlurRegion], strength: BlurStrength, foregroundMask: CIImage? = nil) -> UIImage? {
        guard let source = image.cgImage,
              let output = PrivacyImageRenderer.render(source: source, regions: regions, strength: strength, foregroundMask: foregroundMask) else { return nil }
        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }

    static func renderBackground(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage) {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty,
              let buffer = try? observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler) else {
            throw BlurError.noSubject
        }
        // Vision returns white for selected foreground instances. The renderer's
        // background mask uses white for pixels to blur, so invert the mask.
        let foreground = CIImage(cvPixelBuffer: buffer)
        let extent = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let aligned = foreground
            .transformed(by: CGAffineTransform(translationX: -foreground.extent.minX, y: -foreground.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: CGFloat(cg.width) / foreground.extent.width,
                                               y: CGFloat(cg.height) / foreground.extent.height))
            .cropped(to: extent)
        let mask = CIFilter.colorInvert()
        mask.inputImage = aligned
        guard let backgroundMask = mask.outputImage?.cropped(to: extent) else { throw BlurError.noSubject }
        guard let rendered = render(image, regions: [], strength: strength, foregroundMask: backgroundMask) else { throw BlurError.unavailable }
        return (rendered, backgroundMask)
    }

    static func detectFaces(in image: UIImage) async throws -> [CGRect] {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let request = VNDetectFaceRectanglesRequest()
        try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([request])
        return (request.results ?? []).map { expand(ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox), x: 0.23, y: 0.28) }
    }

    static func detectPlateSuggestions(in image: UIImage) async throws -> [CGRect] {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([request])
        return (request.results ?? []).compactMap { observation in
            let text = observation.boundingBox
            let ratio = text.width / max(text.height, 0.001)
            guard ratio > 1.45, ratio < 8, text.width > 0.05 else { return nil }
            let topLeft = ImageGeometryMapper.topLeftRect(fromVision: text)
            // Vision bounds the glyphs; include the plate border and margin around them.
            return expand(topLeft, x: 0.22, y: 0.48)
        }
    }

    private static func expand(_ rect: CGRect, x: CGFloat, y: CGFloat) -> CGRect {
        let expanded = rect.insetBy(dx: -rect.width * x, dy: -rect.height * y)
        let minX = max(0, expanded.minX), minY = max(0, expanded.minY)
        let maxX = min(1, expanded.maxX), maxY = min(1, expanded.maxY)
        return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
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

enum BlurError: Error { case unavailable, noSubject }
