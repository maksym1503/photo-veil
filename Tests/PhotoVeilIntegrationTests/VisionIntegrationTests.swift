import XCTest
import ImageIO
@testable import ImageGeometry

/// No test-double analyzer here. Real Vision on fixture pixels, outside the PR gate.
final class VisionIntegrationTests: XCTestCase {
    private func image(_ name: String) throws -> CGImage {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "jpg"))
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }
    func testRealFacesAndSmallFaceTiledMapping() throws {
        let large = try FaceDetection.analyze(image("two-faces"))
        XCTAssertGreaterThanOrEqual(large.regions.count, 2)
        let source = try image("faces-small-landscape")
        let baseline = try FaceDetection.analyze(source, tiled: false)
        let tiled = try FaceDetection.analyze(source)
        XCTAssertGreaterThanOrEqual(tiled.regions.count, baseline.regions.count)
        XCTAssertGreaterThan(tiled.regions.count, 0)
        XCTAssertLessThanOrEqual(tiled.requestCount, 21)
        for rect in tiled.regions { XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(rect)) }
        print("Vision faces: baseline=\(baseline.regions.count) tiled=\(tiled.regions.count) requests=\(tiled.requestCount) seconds=\(tiled.elapsed)")
    }
    func testRealDocumentProducesBoundariesAndDetails() throws {
        let output = try DocumentDetection.analyze(image("sample-card"))
        XCTAssertFalse(output.boundaries.isEmpty)
        XCTAssertFalse(output.details.isEmpty)
        for rect in output.boundaries + output.details {
            XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(rect))
        }
        print("Vision documents: boundaries=\(output.boundaries.count) details=\(output.details.count) seconds=\(output.elapsed)")
    }
}
