import XCTest
@testable import ImageGeometry

final class DetectedPrivacySelectionTests: XCTestCase {
    func testCachedReentryReactivatesAllWithoutNewAnalysis() {
        var selection = DetectedPrivacySelection()
        selection.activate(); selection.begin(); selection.complete(count: 3)
        XCTAssertEqual(selection.selected, [0, 1, 2])
        selection.selected.remove(1)
        selection.clear()
        XCTAssertEqual(selection.status, .completed(3))
        XCTAssertFalse(selection.isActive)
        for _ in 0..<10 {
            selection.activate()
            XCTAssertEqual(selection.selected, [0, 1, 2])
            XCTAssertTrue(selection.hasAnalyzed)
            selection.clear()
        }
    }
    func testClearDuringAnalysisDoesNotReactivateOnCompletion() {
        var selection = DetectedPrivacySelection()
        selection.activate(); selection.begin(); selection.clear(); selection.complete(count: 1)
        XCTAssertFalse(selection.isActive)
        selection.activate(); XCTAssertEqual(selection.selected, [0])
    }
    func testFeedbackDistinguishesPendingZeroAndFailure() {
        var selection = DetectedPrivacySelection()
        XCTAssertNil(selection.feedback(for: "faces"))
        selection.activate(); selection.begin()
        XCTAssertNil(selection.feedback(for: "faces"))
        selection.complete(count: 0)
        for category in ["faces", "plates", "documents"] {
            XCTAssertEqual(selection.feedback(for: category), "No \(category) detected. Try Manual.")
        }
        XCTAssertTrue(selection.hasAnalyzed)
        selection.fail()
        XCTAssertEqual(selection.feedback(for: "faces"), "Couldn’t detect faces. Try Manual.")
        XCTAssertTrue(selection.hasAnalyzed)
        XCTAssertFalse(selection.isActive)
    }
}
