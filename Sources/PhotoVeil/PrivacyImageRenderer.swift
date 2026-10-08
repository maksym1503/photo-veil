import CoreGraphics
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

struct BlurRegion: Equatable, Identifiable {
    enum Shape: String, Codable, Equatable { case oval, roundedRectangle, rectangle }
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

/// A category owns its settings independently of the currently selected editing tool.
struct PrivacyEffectSettings: Equatable {
    var strength: BlurStrength = .medium
    var effect: PrivacyEffect = .blur
    var redactionColor: RedactionColor = .black
}

struct PrivacyRenderLayer: Equatable {
    var regions: [BlurRegion] = []
    var strokes: [BlurStroke] = []
    var foregroundMask: CIImage? = nil
    var settings = PrivacyEffectSettings()
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.regions == rhs.regions && lhs.strokes == rhs.strokes && lhs.settings == rhs.settings
            && lhs.foregroundMask === rhs.foregroundMask
    }
}

/// Core Image rendering is synchronous and cannot be interrupted by Task.cancel().
/// Serialize previews; cancelled queued requests never start expensive image evaluation.
/// Export remains independent and always renders the complete requested snapshot.
actor PrivacyPreviewRenderer {
    private let renderImage: (CGImage, [PrivacyRenderLayer]) -> CGImage?
    init(renderImage: @escaping (CGImage, [PrivacyRenderLayer]) -> CGImage? = {
        PrivacyImageRenderer.render(source: $0, layers: $1)
    }) { self.renderImage = renderImage }
    func render(source: CGImage, layers: [PrivacyRenderLayer]) -> CGImage? {
        guard !Task.isCancelled else { return nil }
        let output = renderImage(source, layers)
        return Task.isCancelled ? nil : output
    }
}

/// Shared Core Image pipeline used by both the live canvas preview and full-resolution export.
enum PrivacyImageRenderer {
    private static let context = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])

    static func render(
        source: CGImage,
        regions: [BlurRegion],
        strength: BlurStrength,
        foregroundMask: CIImage? = nil,
        strokes: [BlurStroke] = [],
        effect: PrivacyEffect = .blur,
        redactionColor: RedactionColor = .black
    ) -> CGImage? {
        render(source: source, layers: [PrivacyRenderLayer(regions: regions, strokes: strokes,
            foregroundMask: foregroundMask,
            settings: PrivacyEffectSettings(strength: strength, effect: effect, redactionColor: redactionColor))])
    }

    /// Soft effects run weakest to strongest; opaque redactions run last. Stable ties retain
    /// category order (Background, Faces, Plates, Documents, Manual). Every stage filters and
    /// blends the accumulated image, never the original: a new mask cannot restore source pixels.
    /// Build one CI graph and materialize it once, shared by preview and every export destination.
    static func render(source: CGImage, layers: [PrivacyRenderLayer]) -> CGImage? {
        let active = layers.enumerated().filter {
            $0.element.foregroundMask != nil || !$0.element.regions.isEmpty || !$0.element.strokes.isEmpty
        }.sorted {
            let lhs = $0.element.settings, rhs = $1.element.settings
            if (lhs.effect == .redact) != (rhs.effect == .redact) { return lhs.effect != .redact }
            if lhs.effect != .redact && lhs.strength != rhs.strength {
                return lhs.strength.radius(for: CGSize(width: 900, height: 900)) < rhs.strength.radius(for: CGSize(width: 900, height: 900))
            }
            return $0.offset < $1.offset
        }
        guard !active.isEmpty else { return source }
        var accumulated = CIImage(cgImage: source)
        let extent = accumulated.extent
        for (_, layer) in active {
            guard let output = apply(layer, to: accumulated, extent: extent) else { return nil }
            accumulated = output
        }
        return context.createCGImage(accumulated, from: extent)
    }

    private static func apply(_ layer: PrivacyRenderLayer, to accumulated: CIImage, extent: CGRect) -> CIImage? {
        let settings = layer.settings
        let featherRadius = CGFloat(3 * max(extent.width, extent.height) / 900)
        let effectExtent: CGRect
        if layer.foregroundMask != nil { effectExtent = extent }
        else {
            // Core Image evaluates only the affected ROI, while each filter still reads
            // its full-quality halo from the accumulated image. Include mask feathering.
            let bounds = selectedBounds(layer, in: extent)
            guard !bounds.isNull, !bounds.isEmpty else { return accumulated }
            effectExtent = bounds.insetBy(dx: -ceil(featherRadius * 4), dy: -ceil(featherRadius * 4)).intersection(extent)
        }
        let effected: CIImage
        switch settings.effect {
        case .blur:
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = accumulated.clampedToExtent()
            filter.radius = settings.strength.radius(for: extent.size)
            guard let output = filter.outputImage?.cropped(to: effectExtent) else { return nil }
            effected = output
        case .pixelate:
            let filter = CIFilter.pixellate()
            filter.inputImage = accumulated.clampedToExtent()
            filter.center = CGPoint(x: extent.midX, y: extent.midY)
            filter.scale = settings.strength.radius(for: extent.size) * 1.5
            guard let output = filter.outputImage?.cropped(to: effectExtent) else { return nil }
            effected = output
        case .redact:
            effected = CIImage(color: settings.redactionColor.ciColor).cropped(to: effectExtent)
        }
        let mask: CIImage?
        if let foregroundMask = layer.foregroundMask {
            let bounds = foregroundMask.extent
            mask = foregroundMask
                .transformed(by: CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY))
                .transformed(by: CGAffineTransform(scaleX: extent.width / bounds.width, y: extent.height / bounds.height))
                .cropped(to: extent)
        } else {
            mask = regionMask(size: extent.size, regions: settings.effect == .redact ? layer.regions.map {
                BlurRegion(id: $0.id, rect: $0.rect, shape: $0.shape == .oval ? .oval : .rectangle)
            } : layer.regions, strokes: layer.strokes)
        }
        guard let mask else { return nil }
        let feather = CIFilter.gaussianBlur()
        feather.inputImage = mask.clampedToExtent()
        feather.radius = Float(3 * max(extent.width, extent.height) / 900)
        let softenedMask = settings.effect == .redact ? mask : (feather.outputImage?.cropped(to: extent) ?? mask)
        let blend = CIFilter.blendWithMask()
        blend.inputImage = layer.foregroundMask == nil ? effected : accumulated
        blend.backgroundImage = layer.foregroundMask == nil ? accumulated : effected
        blend.maskImage = softenedMask.cropped(to: effectExtent)
        return blend.outputImage?.cropped(to: extent)
    }

    private static func selectedBounds(_ layer: PrivacyRenderLayer, in extent: CGRect) -> CGRect {
        func imageRect(_ rect: CGRect) -> CGRect {
            CGRect(x: extent.minX + rect.minX * extent.width, y: extent.maxY - rect.maxY * extent.height,
                width: rect.width * extent.width, height: rect.height * extent.height)
        }
        var bounds = CGRect.null
        for region in layer.regions where !region.rect.isNull && !region.rect.isEmpty {
            bounds = bounds.union(imageRect(region.rect))
        }
        for stroke in layer.strokes {
            let radius = stroke.width * min(extent.width, extent.height) / 2
            for point in stroke.points {
                let pixel = CGPoint(x: extent.minX + point.x * extent.width, y: extent.maxY - point.y * extent.height)
                bounds = bounds.union(CGRect(x: pixel.x - radius, y: pixel.y - radius, width: radius * 2, height: radius * 2))
            }
        }
        return bounds
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
            case .rectangle:
                bitmap.addRect(pixelRect)
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
