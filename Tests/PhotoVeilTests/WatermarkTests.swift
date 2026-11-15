import XCTest
import CoreGraphics
import CoreImage
import ImageIO
@testable import ImageGeometry

final class WatermarkTests: XCTestCase {
    func testWatermarkOnlyAddsPixelsAndNilPreservesSource() throws {
        let source = try image(width: 320, height: 220, color: CGColor(red: 0.8, green: 0.12, blue: 0.08, alpha: 1))
        let unchanged = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: nil))
        XCTAssertEqual(pixels(unchanged), pixels(source))
        var watermark = PhotoWatermark(); watermark.rotation = 0
        let layout = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: CGSize(width: 320, height: 220)))
        let tile = try XCTUnwrap(WatermarkRenderer.tile(for: watermark, layout: layout))
        XCTAssertGreaterThan(pixels(tile).filter { $0 > 0 }.count, 0, "Core Text tile must contain visible ink")
        let output = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: watermark))
        XCTAssertEqual(output.width, source.width)
        XCTAssertGreaterThan(differenceCount(output, source), 0, "Watermark-only rendering must produce visible output")
        watermark.rotation = 48
        let rotated = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: watermark))
        XCTAssertGreaterThan(differenceCount(rotated, output), 0, "Rotation changes the rasterized watermark placement")
    }

    func testWatermarkIsCompositedAfterFullRedactionWithoutRestoringSourceColors() throws {
        let source = try image(width: 280, height: 180, color: CGColor(red: 0.85, green: 0.03, blue: 0.16, alpha: 1))
        var watermark = PhotoWatermark(); watermark.rotation = 0
        let layer = PrivacyRenderLayer(regions: [BlurRegion(rect: CGRect(x: 0, y: 0, width: 1, height: 1), shape: .rectangle)],
            settings: PrivacyEffectSettings(effect: .redact, redactionColor: .black))
        let redacted = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [layer]))
        let marked = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [layer], watermark: watermark))
        XCTAssertEqual(pixel(redacted, x: 140, y: 90), [0, 0, 0, 255])
        XCTAssertGreaterThan(differenceCount(marked, redacted), 0, "The watermark remains visible over the redaction")
        for rgba in pixels(marked).chunked(into: 4) where rgba.count == 4 {
            XCTAssertLessThanOrEqual(abs(Int(rgba[0]) - Int(rgba[1])), 2)
            XCTAssertLessThanOrEqual(abs(Int(rgba[1]) - Int(rgba[2])), 2,
                                     "Only neutral watermark ink may appear over black; source red must not return")
        }
    }

    func testLayoutScalesRotatesAndClipsAndRepeatedPlacementsAreBounded() throws {
        var watermark = PhotoWatermark(text: String(repeating: "Veil ", count: 10), center: CGPoint(x: 0, y: 0),
                                      size: 0.08, rotation: 42, repeated: true)
        watermark.center = CGPoint(x: 0.5, y: 0.5)
        let small = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: CGSize(width: 240, height: 160)))
        let large = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: CGSize(width: 960, height: 640)))
        XCTAssertGreaterThan(large.tileSize.width, small.tileSize.width)
        XCTAssertEqual(small.center, CGPoint(x: 120, y: 80))
        XCTAssertGreaterThan(small.bounds.height, small.tileSize.height * 1.5, "Rotation expands the outline bounds before clipping")
        XCTAssertEqual(small.bounds.intersection(CGRect(x: 0, y: 0, width: 240, height: 160)), small.bounds)
        XCTAssertLessThanOrEqual(WatermarkRenderer.placementCenters(for: small, repeated: true,
            imageSize: CGSize(width: 20_000, height: 20_000)).count, WatermarkRenderer.maximumPlacements)
        let shifted = WatermarkLayout(bounds: small.bounds, center: CGPoint(x: small.center.x + 20, y: small.center.y),
                                      tileSize: small.tileSize, fontSize: small.fontSize,
                                      rasterScale: small.rasterScale, rasterSize: small.rasterSize)
        XCTAssertNotEqual(WatermarkRenderer.placementCenters(for: small, repeated: true, imageSize: CGSize(width: 240, height: 160)),
                          WatermarkRenderer.placementCenters(for: shifted, repeated: true, imageSize: CGSize(width: 240, height: 160)),
                          "Dragging changes the repeated pattern phase")
        watermark.rotation = 0
        let unrotated = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: CGSize(width: 240, height: 160)))
        XCTAssertEqual(unrotated.bounds.size, unrotated.tileSize)
    }

    func testLogicalGeometryAndRepeatDensityMatchAcrossPreviewAndExportSizes() throws {
        let watermark = PhotoWatermark(text: "Scale matched text")
        let previewSize = CGSize(width: 1_500, height: 1_000)
        let exportSize = CGSize(width: 6_000, height: 4_000)
        let preview = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: previewSize))
        let export = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: exportSize))
        XCTAssertEqual(export.tileSize.width / exportSize.width, preview.tileSize.width / previewSize.width, accuracy: 0.002)
        XCTAssertEqual(export.tileSize.height / exportSize.height, preview.tileSize.height / previewSize.height, accuracy: 0.002)
        XCTAssertEqual(export.bounds.width / exportSize.width, preview.bounds.width / previewSize.width, accuracy: 0.002)
        XCTAssertEqual(export.bounds.height / exportSize.height, preview.bounds.height / previewSize.height, accuracy: 0.002)
        let previewPlacements = WatermarkRenderer.placementCenters(for: preview, repeated: true, imageSize: previewSize)
        let exportPlacements = WatermarkRenderer.placementCenters(for: export, repeated: true, imageSize: exportSize)
        XCTAssertEqual(previewPlacements.count, exportPlacements.count)
    }

    func testLargeLogicalTileUsesBoundedGlyphRaster() throws {
        let watermark = PhotoWatermark(text: String(repeating: "W", count: 100), size: 0.16, style: .stamp)
        let layout = try XCTUnwrap(WatermarkRenderer.layout(for: watermark, imageSize: CGSize(width: 100_000, height: 100_000)))
        XCTAssertGreaterThan(layout.tileSize.width, CGFloat(WatermarkRenderer.maximumTileDimension))
        XCTAssertLessThan(layout.rasterScale, 1)
        XCTAssertLessThanOrEqual(layout.rasterSize.width, CGFloat(WatermarkRenderer.maximumTileDimension))
        XCTAssertLessThanOrEqual(layout.rasterSize.height, CGFloat(WatermarkRenderer.maximumTileDimension))
        XCTAssertLessThanOrEqual(layout.rasterSize.width * layout.rasterSize.height,
                                 CGFloat(WatermarkRenderer.maximumTilePixels))
        let tile = try XCTUnwrap(WatermarkRenderer.tile(for: watermark, layout: layout))
        XCTAssertLessThanOrEqual(tile.bytesPerRow * tile.height, WatermarkRenderer.maximumTilePixels * 4)
    }

    func testUnicodeBlankAndInvalidWatermarkBoundaries() throws {
        let source = try image(width: 200, height: 120, color: CGColor(gray: 0.3, alpha: 1))
        var unicode = PhotoWatermark(text: "私密 · 🔒 · e\u{301}")
        XCTAssertNotNil(WatermarkRenderer.layout(for: unicode, imageSize: CGSize(width: 200, height: 120)))
        unicode.text = " \t \n"
        let blank = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: unicode))
        XCTAssertEqual(pixels(blank), pixels(source), "Core blank text is an intentional no-op")
        unicode.text = String(repeating: "x", count: PhotoWatermark.maxTextLength + 1)
        XCTAssertNil(PrivacyImageRenderer.render(source: source, layers: [], watermark: unicode))
        unicode.text = "e" + String(repeating: "\u{301}", count: 512)
        XCTAssertFalse(unicode.hasValidText, "Combining sequences are bounded by scalar count as well as graphemes")
        unicode.text = "Valid"
        unicode.opacity = .infinity
        XCTAssertNil(PrivacyImageRenderer.render(source: source, layers: [], watermark: unicode))
        unicode.opacity = 0.5
        unicode.center.x = .nan
        XCTAssertNil(WatermarkRenderer.layout(for: unicode, imageSize: CGSize(width: 200, height: 120)))
        unicode.center = CGPoint(x: 0.5, y: 0.5)
        unicode.text = "line\nbreak"
        XCTAssertFalse(unicode.hasValidText)
    }

    func testPreviewAndInjectedLegacyRendererKeepWatermarkComposition() async throws {
        let source = try image(width: 240, height: 160, color: CGColor(gray: 0.45, alpha: 1))
        let watermark = PhotoWatermark(style: .stamp)
        let previewResult = await PrivacyPreviewRenderer().render(source: source, layers: [], watermark: watermark)
        let preview = try XCTUnwrap(previewResult)
        let exported = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: watermark))
        XCTAssertEqual(pixels(preview), pixels(exported))

        var calls = 0
        let injected = PrivacyPreviewRenderer { source, _ in calls += 1; return source }
        let injectedValue = await injected.render(source: source, layers: [], watermark: watermark)
        let injectedResult = try XCTUnwrap(injectedValue)
        XCTAssertEqual(calls, 1)
        XCTAssertNotEqual(pixels(injectedResult), pixels(source), "Legacy injected closures must not silently drop watermark state")
    }

    func testCancelledInFlightWatermarkPreviewCannotPublish() async throws {
        let source = try image(width: 240, height: 160, color: CGColor(gray: 0.45, alpha: 1))
        let started = expectation(description: "Watermarked preview entered synchronous renderer")
        let release = DispatchSemaphore(value: 0)
        let renderer = PrivacyPreviewRenderer { source, _ in
            started.fulfill()
            XCTAssertEqual(release.wait(timeout: .now() + 5), .success)
            return source
        }
        let task = Task { await renderer.render(source: source, layers: [], watermark: PhotoWatermark()) }
        await fulfillment(of: [started], timeout: 5)
        task.cancel()
        release.signal()
        let output = await task.value
        XCTAssertNil(output, "A cancelled watermark request cannot publish its rendered image")
    }

    func testFlattenedWatermarkSurvivesGalleryReloadAndReexportUnderBothMetadataPolicies() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try image(width: 360, height: 240, color: CGColor(gray: 0.38, alpha: 1))
        let cleanSource = try PhotoExport.encode(source)
        let sourceMetadata = try SourcePhotoMetadata.capture(cleanSource.data)
        var watermark = PhotoWatermark(text: "Synthetic review watermark")
        watermark.rotation = 0
        let markedPixels = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: [], watermark: watermark))
        let cleanPixels = try XCTUnwrap(PrivacyImageRenderer.render(source: source, layers: []))
        let store = try GalleryStore(root: root)
        var ids: [UUID] = []
        for policy in [PhotoMetadataPolicy.remove, .keep] {
            let flattened = try PhotoExport.encode(markedPixels, policy: policy, metadata: policy == .keep ? sourceMetadata : nil)
            let unmarked = try PhotoExport.encode(cleanPixels, policy: policy, metadata: policy == .keep ? sourceMetadata : nil)
            XCTAssertGreaterThan(differenceCount(try decode(flattened.data), try decode(unmarked.data)), 0,
                                 "The visible watermark is present in the flattened export")
            let item = try await store.save(photo: flattened, effect: "Watermark")
            ids.append(item.id)
            XCTAssertEqual(item.effectiveMetadataPolicy, policy)
        }
        let restored = try GalleryStore(root: root)
        let restoredItems = await restored.items()
        for (index, policy) in [PhotoMetadataPolicy.remove, .keep].enumerated() {
            let item = try XCTUnwrap(restoredItems.first(where: { $0.id == ids[index] }))
            XCTAssertEqual(item.effectiveMetadataPolicy, policy)
            let exported = try await restored.exportPhoto(for: item.id)
            XCTAssertEqual(exported.metadataPolicy, policy)
            let original = try PhotoExport.encode(cleanPixels, policy: policy, metadata: policy == .keep ? sourceMetadata : nil)
            XCTAssertGreaterThan(differenceCount(try decode(exported.data), try decode(original.data)), 0,
                                 "Gallery re-export keeps the flattened mark without a recipe")
        }
        let indexBytes = try Data(contentsOf: root.appendingPathComponent("index.json"))
        XCTAssertFalse(String(decoding: indexBytes, as: UTF8.self).contains(watermark.text),
                       "Watermark text is not persisted as editable metadata")
    }

    private func image(width: Int, height: Int, color: CGColor) throws -> CGImage {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try XCTUnwrap(context.makeImage())
    }

    private func decode(_ data: Data) throws -> CGImage {
        try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) })
    }

    private func pixels(_ image: CGImage) -> [UInt8] {
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return bytes
    }

    private func pixel(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        let all = pixels(image), offset = (y * image.width + x) * 4
        return Array(all[offset..<(offset + 4)])
    }

    private func differenceCount(_ lhs: CGImage, _ rhs: CGImage) -> Int {
        zip(pixels(lhs), pixels(rhs)).reduce(into: 0) { if $1.0 != $1.1 { $0 += 1 } }
    }
}

private extension Array where Element == UInt8 {
    func chunked(into size: Int) -> [[UInt8]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}
