import CoreGraphics
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct BlurRegion: Equatable, Identifiable {
    enum Shape: String, Codable, Equatable { case oval, roundedRectangle }
    let id: String
    var rect: CGRect
    var shape: Shape

    init(id: String = UUID().uuidString, rect: CGRect, shape: Shape) {
        self.id = id
        self.rect = rect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        self.shape = shape
    }
}

/// Top-left normalized image points; width is a fraction of the image's shorter edge.
struct BlurStroke: Equatable, Identifiable {
    let id: String
    var points: [CGPoint]
    var width: CGFloat
    init(id: String = UUID().uuidString, points: [CGPoint], width: CGFloat = 0.06) {
        self.id = id
        self.points = points.map { CGPoint(x: min(1, max(0, $0.x)), y: min(1, max(0, $0.y))) }
        self.width = width
    }
}

enum BlurStrength: String, CaseIterable, Identifiable {
    case low = "Low", medium = "Medium", strong = "Strong"
    var id: String { rawValue }

    func radius(for imageSize: CGSize) -> Float {
        let dimension = max(imageSize.width, imageSize.height)
        let scale = dimension / 900
        switch self {
        case .low: return Float(14 * scale)
        case .medium: return Float(28 * scale)
        case .strong: return Float(44 * scale)
        }
    }
}

enum PrivacyEffect: String, Codable, CaseIterable, Identifiable {
    case blur = "Blur", pixelate = "Pixelate", redact = "Redact"
    var id: String { rawValue }
}

enum RedactionColor: String, Codable, CaseIterable, Identifiable {
    case black = "Black", white = "White"
    var id: String { rawValue }
    var ciColor: CIColor { self == .black ? .black : .white }
}

/// Shared Core Image pipeline used by both the live canvas preview and full-resolution export.
enum PrivacyImageRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func render(
        source: CGImage,
        regions: [BlurRegion],
        strength: BlurStrength,
        foregroundMask: CIImage? = nil,
        strokes: [BlurStroke] = [],
        effect: PrivacyEffect = .blur,
        redactionColor: RedactionColor = .black
    ) -> CGImage? {
        let original = CIImage(cgImage: source)
        let extent = original.extent
        let effected: CIImage
        switch effect {
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = original.clampedToExtent()
            filter.radius = strength.radius(for: extent.size)
            guard let output = filter.outputImage?.cropped(to: extent) else { return nil }
            effected = output
        case .pixelate:
            let filter = CIFilter.pixellate()
            filter.inputImage = original.clampedToExtent()
            filter.center = CGPoint(x: extent.midX, y: extent.midY)
            filter.scale = strength.radius(for: extent.size) * 1.5
            guard let output = filter.outputImage?.cropped(to: extent) else { return nil }
            effected = output
        case .redact:
            effected = CIImage(color: redactionColor.ciColor).cropped(to: extent)
        }

        let mask: CIImage?
        if let foregroundMask {
            let bounds = foregroundMask.extent
            mask = foregroundMask
                .transformed(by: CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
                .transformed(by: CGAffineTransform(scaleX: extent.width / bounds.width, y: extent.height / bounds.height))
                .cropped(to: extent)
        } else if !regions.isEmpty || !strokes.isEmpty {
            mask = regionMask(size: CGSize(width: extent.width, height: extent.height), regions: regions, strokes: strokes)
        } else {
            mask = nil
        }
        guard let mask else { return source }

        let feather = CIFilter.gaussianBlur()
        feather.inputImage = mask.clampedToExtent()
        feather.radius = Float(3 * max(extent.width, extent.height) / 900)
        // Solid redaction must not blend readable source detail through a feathered edge.
        let softenedMask = effect == .redact ? mask : (feather.outputImage?.cropped(to: extent) ?? mask)
        let blend = CIFilter.blendWithMask()
        if foregroundMask != nil {
            // White foreground pixels select the sharp original; black background pixels select blur.
            blend.inputImage = original
            blend.backgroundImage = effected
        } else {
            // White selected-region pixels select blur; black pixels retain the original.
            blend.inputImage = effected
            blend.backgroundImage = original
        }
        blend.maskImage = softenedMask
        guard let output = blend.outputImage?.cropped(to: extent) else { return nil }
        return context.createCGImage(output, from: extent)
    }

    /// Reject empty/full masks: they cannot separate a subject from its environment.
    static func hasUsefulForeground(_ mask: CIImage) -> Bool {
        let average = CIFilter.areaAverage()
        average.inputImage = mask
        average.extent = mask.extent
        guard let output = average.outputImage else { return false }
        var pixel = [Float](repeating: 0, count: 4)
        context.render(output, toBitmap: &pixel, rowBytes: 16, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBAf, colorSpace: nil)
        return pixel[0].isFinite && pixel[0] > 0.02 && pixel[0] < 0.98
    }

    static func maskImage(size: CGSize, regions: [BlurRegion]) -> CGImage? {
        regionMask(size: size, regions: regions).flatMap { contextImage($0) }
    }

    private static func contextImage(_ image: CIImage) -> CGImage? {
        context.createCGImage(image, from: image.extent)
    }

    private static func regionMask(size: CGSize, regions: [BlurRegion], strokes: [BlurStroke] = []) -> CIImage? {
        let width = Int(size.width.rounded()), height = Int(size.height.rounded())
        guard width > 0, height > 0,
              let bitmap = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                     space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        bitmap.setFillColor(gray: 0, alpha: 1)
        bitmap.fill(CGRect(x: 0, y: 0, width: width, height: height))
        bitmap.setFillColor(gray: 1, alpha: 1)
        bitmap.saveGState()
        bitmap.translateBy(x: 0, y: CGFloat(height))
        bitmap.scaleBy(x: 1, y: -1)
        for region in regions {
            let r = region.rect
            let pixelRect = CGRect(x: r.minX * CGFloat(width), y: r.minY * CGFloat(height),
                                   width: r.width * CGFloat(width), height: r.height * CGFloat(height))
            switch region.shape {
            case .oval:
                bitmap.addEllipse(in: pixelRect)
            case .roundedRectangle:
                bitmap.addPath(CGPath(roundedRect: pixelRect,
                                      cornerWidth: pixelRect.height * 0.16, cornerHeight: pixelRect.height * 0.16, transform: nil))
            }
            bitmap.fillPath()
        }
        bitmap.setStrokeColor(gray: 1, alpha: 1)
        bitmap.setLineCap(.round)
        bitmap.setLineJoin(.round)
        for stroke in strokes {
            guard let first = stroke.points.first else { continue }
            let diameter = stroke.width * CGFloat(min(width, height))
            func pixelPoint(_ point: CGPoint) -> CGPoint {
                CGPoint(x: point.x * CGFloat(width), y: point.y * CGFloat(height))
            }
            let start = pixelPoint(first)
            if stroke.points.count == 1 {
                bitmap.fillEllipse(in: CGRect(x: start.x - diameter / 2, y: start.y - diameter / 2, width: diameter, height: diameter))
            } else {
                bitmap.setLineWidth(diameter)
                bitmap.move(to: start)
                for point in stroke.points.dropFirst() { bitmap.addLine(to: pixelPoint(point)) }
                bitmap.strokePath()
            }
        }
        bitmap.restoreGState()
        guard let cgMask = bitmap.makeImage() else { return nil }
        return CIImage(cgImage: cgMask)
    }
}
