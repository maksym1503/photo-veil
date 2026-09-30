import XCTest
@testable import ImageGeometry

final class ImageGeometryMapperTests: XCTestCase {
    func testAspectFitAccountsForLetterboxOffsets() {
        let mapper = ImageGeometryMapper(imageSize: CGSize(width: 400, height: 200), container: CGRect(x: 10, y: 20, width: 300, height: 300))
        XCTAssertEqual(mapper.displayedRect, CGRect(x: 10, y: 95, width: 300, height: 150))
        XCTAssertEqual(mapper.viewRect(fromNormalized: CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.4)), CGRect(x: 85, y: 125, width: 150, height: 60))
    }

    func testRoundTripRemainsAlignedAfterZoomAndPan() {
        let mapper = ImageGeometryMapper(imageSize: CGSize(width: 400, height: 800), container: CGRect(x: 0, y: 0, width: 300, height: 500), zoomScale: 2.8, panOffset: CGSize(width: -84, height: 51))
        let source = CGRect(x: 0.63, y: 0.42, width: 0.19, height: 0.11)
        let screen = mapper.viewRect(fromNormalized: source)
        XCTAssertEqual(mapper.normalizedRect(fromView: screen), source)
        XCTAssertNil(mapper.normalizedPoint(fromView: CGPoint(x: -500, y: -500)))
    }

    func testVisionOriginIsFlippedForEditorCoordinates() {
        XCTAssertEqual(ImageGeometryMapper.topLeftRect(fromVision: CGRect(x: 0.2, y: 0.1, width: 0.3, height: 0.25)), CGRect(x: 0.2, y: 0.65, width: 0.3, height: 0.25))
    }
}
