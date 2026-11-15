import CoreGraphics
import CoreImage
import CoreText
import Foundation

enum WatermarkStyle: String, CaseIterable, Identifiable, Sendable {
    case light = "Light"
    case dark = "Dark"
    case stamp = "Stamp"

    var id: String { rawValue }
}

/// Image-space watermark settings. `center` is normalized from the top-left;
/// `rotation` is clockwise degrees in that same coordinate system.
struct PhotoWatermark: Equatable, Sendable {
    static let maxTextLength = 120

    var text = "For verification only"
    var center = CGPoint(x: 0.5, y: 0.5)
    /// Font height as a fraction of the shorter image edge.
    var size: CGFloat = 0.055
    var opacity: CGFloat = 0.58
    var rotation: CGFloat = -25
    var style: WatermarkStyle = .light
    var repeated = false

    var hasValidText: Bool {
        text.utf8.prefix(2_049).count <= 2_048
            && text.unicodeScalars.prefix(513).count <= 512
            && text.prefix(Self.maxTextLength + 1).count <= Self.maxTextLength
            && !text.unicodeScalars.contains(where: { CharacterSet.controlCharacters.union(.newlines).contains($0) })
    }

    var isBlank: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// Pixel geometry in top-left image coordinates, shared by rendering and the editor selection.
struct WatermarkLayout: Equatable, Sendable {
    let bounds: CGRect
    let center: CGPoint
    /// Text and placement geometry in full-resolution source pixels.
    let tileSize: CGSize
    let fontSize: CGFloat
    /// Bounded transparent glyph bitmap scale and dimensions.
    let rasterScale: CGFloat
    let rasterSize: CGSize
}

enum WatermarkRenderer {
    // Core Text work and repeated compositing remain deliberately bounded.
    static let maximumTileDimension = 4_096
    static let maximumTilePixels = 1_500_000
    static let maximumPlacements = 64

    static func layout(for watermark: PhotoWatermark, imageSize: CGSize) -> WatermarkLayout? {
        guard isValid(watermark, imageSize: imageSize), !watermark.isBlank else { return nil }
        let shorter = min(imageSize.width, imageSize.height)
        var fontSize = max(1, shorter * watermark.size)
        let maxWidth = imageSize.width * 0.92
        var metrics = lineMetrics(watermark, fontSize: fontSize)
        var padding = tilePadding(style: watermark.style, fontSize: fontSize)
        var availableWidth = maxWidth - padding * 2
        guard availableWidth >= 1 else { return nil }
        for _ in 0..<8 where metrics.width > availableWidth {
            fontSize *= availableWidth / metrics.width * 0.98
            guard fontSize >= 0.5 else { return nil }
            padding = tilePadding(style: watermark.style, fontSize: fontSize)
            availableWidth = maxWidth - padding * 2
            metrics = lineMetrics(watermark, fontSize: fontSize)
        }
        guard metrics.width <= availableWidth else { return nil }
        let tile = CGSize(width: ceil(metrics.width + padding * 2),
                          height: ceil(metrics.ascent + metrics.descent + metrics.leading + padding * 2))
        guard tile.width <= maxWidth,
              tile.width <= 100_000, tile.height <= 100_000,
              tile.width * tile.height > 0, (tile.width * tile.height).isFinite else { return nil }

        var rasterScale = min(1, CGFloat(maximumTileDimension) / tile.width,
                              CGFloat(maximumTileDimension) / tile.height,
                              sqrt(CGFloat(maximumTilePixels) / (tile.width * tile.height)))
        var rasterWidth = ceil(tile.width * rasterScale)
        var rasterHeight = ceil(tile.height * rasterScale)
        while rasterWidth * rasterHeight > CGFloat(maximumTilePixels) {
            rasterScale *= 0.999
            rasterWidth = ceil(tile.width * rasterScale)
            rasterHeight = ceil(tile.height * rasterScale)
        }
        guard rasterScale > 0, rasterWidth > 0, rasterHeight > 0,
              rasterWidth <= CGFloat(maximumTileDimension), rasterHeight <= CGFloat(maximumTileDimension) else { return nil }
        let rasterSize = CGSize(width: rasterWidth, height: rasterHeight)

        let center = CGPoint(x: watermark.center.x * imageSize.width, y: watermark.center.y * imageSize.height)
        let radians = -watermark.rotation * .pi / 180
        let rotatedWidth = abs(tile.width * cos(radians)) + abs(tile.height * sin(radians))
        let rotatedHeight = abs(tile.width * sin(radians)) + abs(tile.height * cos(radians))
        let bounds = CGRect(x: center.x - rotatedWidth / 2, y: center.y - rotatedHeight / 2,
                            width: rotatedWidth, height: rotatedHeight)
            .intersection(CGRect(origin: .zero, size: imageSize))
        return WatermarkLayout(bounds: bounds, center: center, tileSize: tile, fontSize: fontSize,
                               rasterScale: rasterScale, rasterSize: rasterSize)
    }

    static func isValid(_ watermark: PhotoWatermark, imageSize: CGSize) -> Bool {
        imageSize.width.isFinite && imageSize.height.isFinite && imageSize.width > 0 && imageSize.height > 0
            && imageSize.width <= 100_000 && imageSize.height <= 100_000
            && watermark.hasValidText
            && watermark.center.x.isFinite && watermark.center.y.isFinite
            && (0...1).contains(watermark.center.x) && (0...1).contains(watermark.center.y)
            && watermark.size.isFinite && (0.012...0.16).contains(watermark.size)
            && watermark.opacity.isFinite && (0...1).contains(watermark.opacity)
            && watermark.rotation.isFinite && abs(watermark.rotation) <= 360
    }

    static func tile(for watermark: PhotoWatermark, layout: WatermarkLayout) -> CGImage? {
        let width = Int(layout.rasterSize.width)
        let height = Int(layout.rasterSize.height)
        guard width > 0, height > 0, width <= maximumTileDimension, height <= maximumTileDimension,
              width * height <= maximumTilePixels,
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        let fontSize = layout.fontSize
        let inset = tilePadding(style: watermark.style, fontSize: fontSize)
        context.saveGState()
        context.scaleBy(x: layout.rasterScale, y: layout.rasterScale)
        if watermark.style == .stamp {
            let background = watermark.opacity * 0.82
            context.setFillColor(CGColor(gray: watermarkIsLight(watermark) ? 0 : 1, alpha: background))
            context.fill(CGRect(x: inset / 2, y: inset / 2, width: CGFloat(width) - inset,
                                height: CGFloat(height) - inset))
        }
        let metrics = lineMetrics(watermark, fontSize: fontSize)
        context.textMatrix = .identity
        context.setTextDrawingMode(.fill)
        context.textPosition = CGPoint(x: inset, y: inset + metrics.descent)
        CTLineDraw(metrics.line, context)
        context.restoreGState()
        return context.makeImage()
    }

    static func placementCenters(for layout: WatermarkLayout, repeated: Bool, imageSize: CGSize) -> [CGPoint] {
        guard repeated else { return [layout.center] }
        var dx = max(layout.tileSize.width * 2.4, imageSize.width / 7)
        var dy = max(layout.tileSize.height * 2.8, imageSize.height / 6)
        let initialCount = (ceil(imageSize.width / dx) + 2) * (ceil(imageSize.height / dy) + 2)
        if initialCount > CGFloat(maximumPlacements) {
            let scale = sqrt(initialCount / CGFloat(maximumPlacements))
            dx *= scale
            dy *= scale
        }
        let phaseX = layout.center.x.truncatingRemainder(dividingBy: dx)
        let phaseY = layout.center.y.truncatingRemainder(dividingBy: dy)
        var centers: [CGPoint] = []
        var y = phaseY - dy
        while y < imageSize.height + dy && centers.count < maximumPlacements {
            var x = phaseX - dx
            while x < imageSize.width + dx && centers.count < maximumPlacements {
                centers.append(CGPoint(x: x, y: y))
                x += dx
            }
            y += dy
        }
        return centers
    }

    static func rotated(_ image: CIImage, degreesClockwise: CGFloat, center: CGPoint) -> CIImage {
        let radians = -degreesClockwise * .pi / 180
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: radians).translatedBy(x: -center.x, y: -center.y)
        return image.transformed(by: transform)
    }

    private static func attributedText(_ watermark: PhotoWatermark, fontSize: CGFloat) -> CFAttributedString {
        let font = CTFontCreateWithName("HelveticaNeue-Medium" as CFString, fontSize, nil)
        let light = watermarkIsLight(watermark)
        let foreground = CGColor(gray: light ? 1 : 0.08, alpha: watermark.opacity)
        let stroke = CGColor(gray: light ? 0 : 1, alpha: watermark.opacity * 0.38)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): foreground,
            NSAttributedString.Key(kCTStrokeColorAttributeName as String): stroke,
            NSAttributedString.Key(kCTStrokeWidthAttributeName as String): -0.8
        ]
        return NSAttributedString(string: watermark.text, attributes: attributes) as CFAttributedString
    }

    private static func lineMetrics(_ watermark: PhotoWatermark, fontSize: CGFloat)
        -> (line: CTLine, width: CGFloat, ascent: CGFloat, descent: CGFloat, leading: CGFloat) {
        let line = CTLineCreateWithAttributedString(attributedText(watermark, fontSize: fontSize))
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        return (line, width, ascent, descent, leading)
    }

    private static func tilePadding(style: WatermarkStyle, fontSize: CGFloat) -> CGFloat {
        style == .stamp ? max(4, fontSize * 0.38) : max(2, fontSize * 0.16)
    }

    private static func watermarkIsLight(_ watermark: PhotoWatermark) -> Bool {
        watermark.style != .dark
    }
}
