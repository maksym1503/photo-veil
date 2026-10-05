import XCTest
@testable import ImageGeometry

final class FaceDetectionTests: XCTestCase {
    func testBoundedOverlappingTilesCoverPortraitAndLandscape() {
        for size in [CGSize(width: 4032, height: 3024), CGSize(width: 3024, height: 4032)] {
            let tiles = FaceDetection.tiles(for: size)
            XCTAssertEqual(tiles.count, 6)
            for y in stride(from: 0.0, through: 1.0, by: 0.1) {
                for x in stride(from: 0.0, through: 1.0, by: 0.1) {
                    XCTAssertTrue(tiles.contains { $0.insetBy(dx: -0.001, dy: -0.001).contains(CGPoint(x: x, y: y)) })
                }
            }
        }
        XCTAssertTrue(FaceDetection.tiles(for: CGSize(width: 1800, height: 1200)).isEmpty)
    }
    func testTileMappingDoesNotDependOnZoom() {
        let mapped = FaceDetection.map(CGRect(x: 0.5, y: 0.25, width: 0.1, height: 0.2),
                                       through: CGRect(x: 0.4, y: 0.3, width: 0.6, height: 0.6))
        XCTAssertEqual(mapped.minX, 0.7, accuracy: 0.000001)
        XCTAssertEqual(mapped.minY, 0.45, accuracy: 0.000001)
        XCTAssertEqual(mapped.width, 0.06, accuracy: 0.000001)
        XCTAssertEqual(mapped.height, 0.12, accuracy: 0.000001)
    }
    func testMergeRemovesCropDuplicatesAndPreservesNearbyFaces() {
        let first = CGRect(x: 0.2, y: 0.3, width: 0.1, height: 0.15)
        let duplicate = first.insetBy(dx: 0.008, dy: 0.01)
        let neighbor = first.offsetBy(dx: 0.12, dy: 0)
        XCTAssertEqual(FaceDetection.merge([duplicate, neighbor, first]).count, 2)
        XCTAssertTrue(FaceDetection.merge([duplicate, neighbor, first]).contains(first))
    }
}
