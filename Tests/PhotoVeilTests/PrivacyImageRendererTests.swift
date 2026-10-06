import XCTest
import CoreImage
@testable import ImageGeometry

final class PrivacyImageRendererTests: XCTestCase {
    func testForegroundMaskSelectsSharpSubjectAndBlursEnvironment() throws {
        let source = try checkerboard(width: 160, height: 120)
        let mask = try mask(width: 160, height: 120, rect: CGRect(x: 48, y: 24, width: 64, height: 80))
        let result = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, foregroundMask: mask))

        XCTAssertEqual(pixel(result, x: 72, y: 56), pixel(source, x: 72, y: 56), "White mask pixels must preserve the foreground exactly")
        XCTAssertNotEqual(pixel(result, x: 12, y: 12), pixel(source, x: 12, y: 12), "Black mask pixels must blur the environment")
    }

    func testForegroundMaskIsMappedWithoutVerticalInversion() throws {
        let source = try checkerboard(width: 160, height: 120)
        let topForeground = try mask(width: 160, height: 120, rect: CGRect(x: 48, y: 8, width: 64, height: 42))
        let result = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, foregroundMask: topForeground))

        XCTAssertEqual(pixel(result, x: 72, y: 24), pixel(source, x: 72, y: 24), "Top-half foreground pixels must remain sharp")
        XCTAssertNotEqual(pixel(result, x: 72, y: 96), pixel(source, x: 72, y: 96), "The lower environment must blur")
    }

    func testSelectedPlateRectangleIsBlurredAndOutsideStaysSharp() throws {
        let source = try checkerboard(width: 240, height: 140)
        let plate = BlurRegion(rect: CGRect(x: 0.56, y: 0.56, width: 0.30, height: 0.24), shape: .roundedRectangle)
        let result = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [plate], strength: .strong))

        XCTAssertNotEqual(pixel(result, x: 168, y: 98), pixel(source, x: 168, y: 98), "The selected plate interior must blur")
        XCTAssertEqual(pixel(result, x: 24, y: 20), pixel(source, x: 24, y: 20), "Pixels outside the selected region must remain sharp")
    }

    func testManualRegionUsesTopLeftImageCoordinatesAndKeepsAspectRatio() throws {
        let source = try checkerboard(width: 240, height: 140)
        let region = BlurRegion(rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.25), shape: .roundedRectangle)
        let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [region], strength: .strong))
        XCTAssertEqual(output.width, source.width)
        XCTAssertEqual(output.height, source.height)
        XCTAssertNotEqual(pixel(output, x: 48, y: 28), pixel(source, x: 48, y: 28))
        XCTAssertEqual(pixel(output, x: 48, y: 112), pixel(source, x: 48, y: 112))
    }

    func testCachedForegroundMaskScalesToFullResolutionExport() throws {
        let source = try checkerboard(width: 240, height: 160)
        let previewMask = try mask(width: 120, height: 80, rect: CGRect(x: 36, y: 12, width: 48, height: 48))
        let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, foregroundMask: previewMask))
        XCTAssertEqual(pixel(output, x: 100, y: 50), pixel(source, x: 100, y: 50))
        XCTAssertNotEqual(pixel(output, x: 12, y: 12), pixel(source, x: 12, y: 12))
        XCTAssertEqual(output.width, 240)
        XCTAssertEqual(output.height, 160)
    }

    func testBlurRadiusScalesEquallyForPreviewAndExport() {
        for strength in BlurStrength.allCases {
            XCTAssertEqual(strength.radius(for: CGSize(width: 400, height: 300)) * 10,
                           strength.radius(for: CGSize(width: 4000, height: 3000)), accuracy: 0.001)
        }
    }

    func testEmptyOrFullForegroundMaskIsRejected() throws {
        let extent = CGRect(x: 0, y: 0, width: 240, height: 160)
        XCTAssertFalse(PrivacyImageRenderer.hasUsefulForeground(CIImage(color: .black).cropped(to: extent)))
        XCTAssertFalse(PrivacyImageRenderer.hasUsefulForeground(CIImage(color: .white).cropped(to: extent)))
        XCTAssertTrue(PrivacyImageRenderer.hasUsefulForeground(try mask(width: 240, height: 160, rect: CGRect(x: 80, y: 20, width: 80, height: 120))))
    }

    func testStrokeMaskBlursOnlyPaintedPixelsAtEveryStrength() throws {
        let source = try checkerboard(width: 240, height: 140)
        let stroke = BlurStroke(points: [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.7, y: 0.2)], width: 0.15)
        var interiors: [[UInt8]] = []
        for strength in BlurStrength.allCases {
            let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: strength, strokes: [stroke]))
            XCTAssertNotEqual(pixel(output, x: 80, y: 28), pixel(source, x: 80, y: 28))
            XCTAssertEqual(pixel(output, x: 80, y: 112), pixel(source, x: 80, y: 112))
            interiors.append(pixel(output, x: 80, y: 28))
        }
        XCTAssertNotEqual(interiors[0], interiors[2])
    }

    func testPlateStrengthChangesRenderedPixelsAndEmptySelectionKeepsOriginal() throws {
        let source = try checkerboard(width: 240, height: 140)
        let plate = BlurRegion(rect: CGRect(x: 0.5, y: 0.5, width: 0.4, height: 0.3), shape: .roundedRectangle)
        let low = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [plate], strength: .low))
        let strong = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [plate], strength: .strong))
        XCTAssertNotEqual(pixel(low, x: 152, y: 88), pixel(strong, x: 152, y: 88))
        let empty = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong))
        XCTAssertEqual(pixel(empty, x: 152, y: 88), pixel(source, x: 152, y: 88))
    }

    func testEveryEffectAndShapePreservesUnselectedPixels() throws {
        let source = try checkerboard(width: 240, height: 160)
        for effect in PrivacyEffect.allCases {
            for shape in [BlurRegion.Shape.roundedRectangle, .oval] {
                let region = BlurRegion(rect: CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5), shape: shape)
                let result = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [region], strength: .strong, effect: effect))
                XCTAssertEqual(pixel(result, x: 228, y: 150), pixel(source, x: 228, y: 150))
                if effect == .redact { XCTAssertEqual(Array(pixel(result, x: 100, y: 65).prefix(3)), [0, 0, 0]) }
                else { XCTAssertNotEqual(pixel(result, x: 100, y: 65), pixel(source, x: 100, y: 65)) }
            }
        }
    }

    func testSolidRedactionDoesNotFeatherAndSupportsWhiteBrush() throws {
        let source = try checkerboard(width: 240, height: 160)
        let region = BlurRegion(rect: CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.5), shape: .roundedRectangle)
        let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [region], strength: .low, effect: .redact))
        XCTAssertEqual(Array(pixel(output, x: 49, y: 65).prefix(3)), [0, 0, 0])
        XCTAssertEqual(pixel(output, x: 46, y: 65), pixel(source, x: 46, y: 65))
        let stroke = BlurStroke(points: [CGPoint(x: 0.2, y: 0.3), CGPoint(x: 0.8, y: 0.3)], width: 0.2)
        let brushed = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, strokes: [stroke], effect: .redact, redactionColor: .white))
        XCTAssertEqual(Array(pixel(brushed, x: 90, y: 48).prefix(3)), [255, 255, 255])
    }

    func testSolidPreviewAndExportMaskSemanticsAtDifferentResolutions() throws {
        let region = BlurRegion(rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), shape: .oval)
        let preview = try XCTUnwrap(PrivacyImageRenderer.render(source: checkerboard(width: 240, height: 160), regions: [region], strength: .medium, effect: .redact))
        let export = try XCTUnwrap(PrivacyImageRenderer.render(source: checkerboard(width: 480, height: 320), regions: [region], strength: .medium, effect: .redact))
        for point in [CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.5, y: 0.3)] {
            XCTAssertEqual(pixel(preview, x: Int(point.x * 240), y: Int(point.y * 160)),
                           pixel(export, x: Int(point.x * 480), y: Int(point.y * 320)))
        }
    }

    func testPixelateBrushAndBackgroundUseSharedMaskSemantics() throws {
        let source = try checkerboard(width: 240, height: 160)
        let stroke = BlurStroke(points: [CGPoint(x: 0.2, y: 0.2), CGPoint(x: 0.8, y: 0.2)], width: 0.15)
        let brush = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, strokes: [stroke], effect: .pixelate))
        XCTAssertNotEqual(pixel(brush, x: 80, y: 32), pixel(source, x: 80, y: 32))
        XCTAssertEqual(pixel(brush, x: 80, y: 145), pixel(source, x: 80, y: 145))
        let foreground = try mask(width: 120, height: 80, rect: CGRect(x: 36, y: 12, width: 48, height: 48))
        for effect in [PrivacyEffect.pixelate, .redact] {
            let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [], strength: .strong, foregroundMask: foreground, effect: effect))
            XCTAssertEqual(pixel(output, x: 100, y: 50), pixel(source, x: 100, y: 50))
            // Pixelation samples a block's source color, so individual pixels can remain equal.
            let changedBackground = (8..<28).contains { x in
                (8..<28).contains { y in pixel(output, x: x, y: y) != pixel(source, x: x, y: y) }
            }
            XCTAssertTrue(changedBackground)
        }
    }

    func testNormalizedPixelGridScalesFromPreviewToExport() throws {
        let source = try checkerboard(width: 240, height: 160)
        let context = try XCTUnwrap(CGContext(data: nil, width: 480, height: 320, bitsPerComponent: 8, bytesPerRow: 1920,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.interpolationQuality = .none; context.draw(source, in: CGRect(x: 0, y: 0, width: 480, height: 320))
        let region = BlurRegion(rect: CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7), shape: .rectangle)
        let preview = try XCTUnwrap(PrivacyImageRenderer.render(source: source, regions: [region], strength: .medium, effect: .pixelate))
        let export = try XCTUnwrap(PrivacyImageRenderer.render(source: XCTUnwrap(context.makeImage()), regions: [region], strength: .medium, effect: .pixelate))
        for point in [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.7, y: 0.6)] {
            let p = pixel(preview, x: Int(point.x * 240), y: Int(point.y * 160))
            let e = pixel(export, x: Int(point.x * 480), y: Int(point.y * 320))
            for channel in 0..<3 { XCTAssertEqual(Double(p[channel]), Double(e[channel]), accuracy: 2) }
        }
    }

    func testEveryRequestedLayerCombinationAndDestinationParity() throws {
        let source = try checkerboard(width: 500, height: 320)
        let rectangles = (0..<5).map { index in
            BlurRegion(rect: CGRect(x: 0.05 + Double(index) * 0.18, y: 0.3, width: 0.13, height: 0.4), shape: .rectangle)
        }
        var layers = rectangles.map { PrivacyRenderLayer(regions: [$0], settings: PrivacyEffectSettings(strength: .strong)) }
        layers[0] = PrivacyRenderLayer(foregroundMask: try mask(width: 500, height: 320,
            rect: CGRect(x: 115, y: 0, width: 385, height: 320)), settings: PrivacyEffectSettings(strength: .strong))
        // Background/Faces/Plates/Documents/Manual: every requested two-, three- and five-layer combination.
        let combinations = [[1,2], [1,4], [2,4], [0,1], [3,4], [1,2,4], [0,1,2], [1,2,3], [0,1,2,3,4]]
        for indices in combinations {
            let snapshot = indices.map { layers[$0] }
            let live = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: snapshot))
            let exported = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: snapshot))
            XCTAssertEqual(live.dataProvider?.data as Data?, exported.dataProvider?.data as Data?)
            for index in indices {
                let x = Int((rectangles[index].rect.midX * 500).rounded())
                XCTAssertNotEqual(pixel(live, x: x, y: 160), pixel(source, x: x, y: 160), "Missing layer \(index) in \(indices)")
            }
        }
    }

    func testOverlappingBackgroundAndMixedEffectsNeverRestoreOriginalOrSolidRedaction() throws {
        let source = try checkerboard(width: 240, height: 160)
        let region = BlurRegion(rect: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6), shape: .rectangle)
        let redaction = PrivacyRenderLayer(regions: [region], settings: PrivacyEffectSettings(effect: .redact))
        let background = PrivacyRenderLayer(foregroundMask: try mask(width: 240, height: 160, rect: CGRect(x: 0, y: 0, width: 120, height: 160)))
        let blur = PrivacyRenderLayer(regions: [region], settings: PrivacyEffectSettings(strength: .strong))
        let pixelate = PrivacyRenderLayer(regions: [region], settings: PrivacyEffectSettings(effect: .pixelate))
        for layers in [[redaction, background], [redaction, blur, pixelate, background], [background, pixelate, blur, redaction]] {
            let result = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: layers))
            XCTAssertEqual(Array(pixel(result, x: 72, y: 56).prefix(3)), [0, 0, 0])
        }
        let prior = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [blur]))
        let combined = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [blur, background]))
        // White foreground selects the accumulated blurred face, never the original sharp face.
        for channel in 0..<3 { XCTAssertEqual(Double(pixel(combined, x: 72, y: 56)[channel]), Double(pixel(prior, x: 72, y: 56)[channel]), accuracy: 1) }
        XCTAssertNotEqual(pixel(combined, x: 72, y: 56), pixel(source, x: 72, y: 56))
    }

    func testDifferentEffectsRemainIndependentAndClearingLayerKeepsOthers() throws {
        let source = try checkerboard(width: 500, height: 320)
        let regions = (0..<3).map { BlurRegion(rect: CGRect(x: 0.05 + Double($0) * 0.3, y: 0.2, width: 0.2, height: 0.6), shape: .rectangle) }
        let layers = [PrivacyRenderLayer(regions: [regions[0]], settings: PrivacyEffectSettings(strength: .strong)),
                      PrivacyRenderLayer(regions: [regions[1]], settings: PrivacyEffectSettings(effect: .pixelate)),
                      PrivacyRenderLayer(regions: [regions[2]], settings: PrivacyEffectSettings(effect: .redact))]
        let combined = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: layers))
        XCTAssertEqual(Array(pixel(combined, x: 375, y: 160).prefix(3)), [0,0,0])
        for cleared in 0..<3 {
            let remaining = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: layers.enumerated().filter { $0.offset != cleared }.map { $0.element }))
            let x = Int(regions[cleared].rect.midX * 500)
            XCTAssertEqual(pixel(remaining, x: x, y: 160), pixel(source, x: x, y: 160))
            for preserved in (0..<3).filter({ $0 != cleared }) {
                let px = Int(regions[preserved].rect.midX * 500)
                for channel in 0..<3 { XCTAssertEqual(Double(pixel(remaining, x: px, y: 160)[channel]), Double(pixel(combined, x: px, y: 160)[channel]), accuracy: 1) }
            }
        }
    }

    private func checkerboard(width: Int, height: Int) throws -> CGImage {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                     space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else {
            throw NSError(domain: "test", code: 1)
        }
        for y in stride(from: 0, to: height, by: 8) {
            for x in stride(from: 0, to: width, by: 8) {
                let white = ((x / 8) + (y / 8)).isMultiple(of: 2)
                context.setFillColor(red: white ? 1 : 0, green: white ? 1 : 0.08, blue: white ? 1 : 0.12, alpha: 1)
                context.fill(CGRect(x: x, y: y, width: min(8, width - x), height: min(8, height - y)))
            }
        }
        return try XCTUnwrap(context.makeImage())
    }

    private func mask(width: Int, height: Int, rect: CGRect) throws -> CIImage {
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                                     space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            throw NSError(domain: "test", code: 2)
        }
        context.setFillColor(gray: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.saveGState()
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(gray: 1, alpha: 1)
        context.fill(rect)
        context.restoreGState()
        return CIImage(cgImage: try XCTUnwrap(context.makeImage()))
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        let data = image.dataProvider!.data! as Data
        let index = y * image.bytesPerRow + x * (image.bitsPerPixel / 8)
        return Array(data[index..<(index + 4)])
    }
}
