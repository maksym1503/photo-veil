import XCTest
@testable import ImageGeometry

final class DocumentDetectionTests: XCTestCase {
    func testCardHeuristicDoesNotPretendToClassifyNamesOrEveryNumber() {
        XCTAssertTrue(DocumentDetection.isCardNumberLike("4111 1111 1111 1111"))
        XCTAssertTrue(DocumentDetection.isCardNumberLike("5555-4444-3333-2222"))
        XCTAssertFalse(DocumentDetection.isCardNumberLike("12/28"))
        XCTAssertFalse(DocumentDetection.isCardNumberLike("Account 4111111111111111"))
        XCTAssertFalse(DocumentDetection.isCardNumberLike("Jane Example"))
    }
}
