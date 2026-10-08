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
        guard let source = image.cgImage else { return nil }
        let scale = min(1, CGFloat(maxDimension) / CGFloat(max(source.width, source.height)))
        guard scale < 1 else { return image }
        let scaled = CIImage(cgImage: source).applyingFilter("CILanczosScaleTransform", parameters: [
            kCIInputScaleKey: scale, kCIInputAspectRatioKey: 1
        ])
        guard let thumbnail = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: thumbnail, scale: 1, orientation: .up)
    }

    static func render(_ image: UIImage, regions: [BlurRegion], strength: BlurStrength, foregroundMask: CIImage? = nil, strokes: [BlurStroke] = [], effect: PrivacyEffect = .blur, redactionColor: RedactionColor = .black) -> UIImage? {
        guard let source = image.cgImage,
              let output = PrivacyImageRenderer.render(source: source, regions: regions, strength: strength, foregroundMask: foregroundMask, strokes: strokes, effect: effect, redactionColor: redactionColor) else { return nil }
        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }

    static func renderBackground(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage) {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)
        let request = VNGenerateForegroundInstanceMaskRequest()
        #if targetEnvironment(simulator)
        request.usesCPUOnly = true
        #endif
        try handler.perform([request])
        guard let observation = request.results?.first, !observation.allInstances.isEmpty,
              let buffer = try? observation.generateScaledMaskForImage(forInstances: observation.allInstances, from: handler) else {
            throw BlurError.noSubject
        }
        // Vision white = foreground, black = environment. Pass it unchanged:
        // the renderer selects original pixels with white, blurred pixels with black.
        let foreground = CIImage(cvPixelBuffer: buffer)
        let extent = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let aligned = foreground
            .transformed(by: CGAffineTransform(translationX: -foreground.extent.minX, y: -foreground.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: CGFloat(cg.width) / foreground.extent.width,
                                               y: CGFloat(cg.height) / foreground.extent.height))
            .cropped(to: extent)
        guard PrivacyImageRenderer.hasUsefulForeground(aligned) else { throw BlurError.noSubject }
        guard let rendered = render(image, regions: [], strength: strength, foregroundMask: aligned) else { throw BlurError.unavailable }
        return (rendered, aligned)
    }

    static func detectFaces(in image: UIImage) async throws -> [CGRect] {
        guard let cg = image.cgImage else { throw BlurError.unavailable }
        let report = try FaceDetection.analyze(cg)
        return report.regions.map { expand($0, x: 0.23, y: 0.28) }
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
