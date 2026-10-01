import CoreGraphics
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct BlurRegion: Equatable, Identifiable {
    enum Shape: Equatable { case oval, roundedRectangle }
    let id: String
    var rect: CGRect
    var shape: Shape

    init(id: String = UUID().uuidString, rect: CGRect, shape: Shape) {
        self.id = id
        self.rect = rect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        self.shape = shape
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

/// Shared Core Image pipeline used by both the live canvas preview and full-resolution export.
enum PrivacyImageRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func render(
        source: CGImage,
        regions: [BlurRegion],
        strength: BlurStrength,
        foregroundMask: CIImage? = nil
    ) -> CGImage? {
        let original = CIImage(cgImage: source)
        let extent = original.extent
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = original.clampedToExtent()
        filter.radius = strength.radius(for: CGSize(width: extent.width, height: extent.height))
        guard let blurred = filter.outputImage?.cropped(to: extent) else { return nil }

        let mask: CIImage?
        if let foregroundMask {
            let bounds = foregroundMask.extent
            mask = foregroundMask
                .transformed(by: CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
                .transformed(by: CGAffineTransform(scaleX: extent.width / bounds.width, y: extent.height / bounds.height))
                .cropped(to: extent)
        } else if !regions.isEmpty {
            mask = regionMask(size: CGSize(width: extent.width, height: extent.height), regions: regions)
        } else {
            mask = nil
        }
        guard let mask else { return source }

        let feather = CIFilter.gaussianBlur()
        feather.inputImage = mask.clampedToExtent()
        feather.radius = Float(3 * max(extent.width, extent.height) / 900)
        let softenedMask = feather.outputImage?.cropped(to: extent) ?? mask
        let blend = CIFilter.blendWithMask()
        if foregroundMask != nil {
            // White foreground pixels select the sharp original; black background pixels select blur.
            blend.inputImage = original
            blend.backgroundImage = blurred
        } else {
            // White selected-region pixels select blur; black pixels retain the original.
            blend.inputImage = blurred
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

    private static func regionMask(size: CGSize, regions: [BlurRegion]) -> CIImage? {
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
        bitmap.restoreGState()
        guard let cgMask = bitmap.makeImage() else { return nil }
        return CIImage(cgImage: cgMask)
    }
}
