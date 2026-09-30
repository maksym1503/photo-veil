import XCTest
@testable import ImageGeometry

final class ImageGeometryMapperTests: XCTestCase {
    func testAspectFitAccountsForLetterboxOffsets() {
        let mapper = ImageGeometryMapper(imageSize: CGSize(width: 400, height: 200), container: CGRect(x: 10, y: 20, width: 300, height: 300))
        XCTAssertEqual(mapper.displayedRect, CGRect(x: 10, y: 95, width: 300, height: 150))
        XCTAssertEqual(mapper.viewRect(fromNormalized: CGRect(x: 0.25, y: 0.2, width: 0.5, height: 0.4)), CGRect(x: 85, y: 125, width: 150, height: 60))
    }

    func testViewToImageRoundTripAndRejectsLetterbox() {
        let mapper = ImageGeometryMapper(imageSize: CGSize(width: 200, height: 400), container: CGRect(x: 0, y: 0, width: 300, height: 300))
        XCTAssertNil(mapper.normalizedPoint(fromView: CGPoint(x: 20, y: 150)))
        let original = CGRect(x: 0.15, y: 0.2, width: 0.4, height: 0.3)
        let mapped = mapper.viewRect(fromNormalized: original)
        XCTAssertEqual(mapper.normalizedRect(fromView: mapped), original)
    }

    func testVisionOriginIsFlippedForEditorCoordinates() {
        XCTAssertEqual(ImageGeometryMapper.topLeftRect(fromVision: CGRect(x: 0.2, y: 0.1, width: 0.3, height: 0.25)), CGRect(x: 0.2, y: 0.65, width: 0.3, height: 0.25))
    }
}
