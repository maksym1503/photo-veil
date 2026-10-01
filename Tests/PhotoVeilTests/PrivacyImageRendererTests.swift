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
        let index = (y * image.width + x) * 4
        return Array(data[index..<(index + 4)])
    }
}
