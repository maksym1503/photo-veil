import XCTest
@testable import ImageGeometry

final class DetectedPrivacySelectionTests: XCTestCase {
    func testHighVolumeAutomaticHistoryCannotEvictAnyManualSnapshot() {
        var history = ScopedUndoHistory<String, String>()
        for index in 0..<30 { history.append("manual-\(index)", for: "manual") }
        let automatic = ["background", "faces", "plates", "documents"]
        var selections = automatic.map { _ in DetectedPrivacySelection() }
        for index in selections.indices {
            selections[index].activate(); selections[index].begin(); selections[index].complete(count: index + 1)
        }
        for edit in 0..<1000 {
            for (index, category) in automatic.enumerated() {
                history.append("\(category)-\(edit)", for: category)
                selections[index].clear(); selections[index].activate()
                XCTAssertEqual(selections[index].selected, Set(0..<(index + 1)))
                XCTAssertEqual(selections[index].status, .completed(index + 1), "Re-entry must retain cached analysis")
            }
        }
        // All categories retain exactly their own last 30 snapshots, in reverse order.
        // Popping one category neither consumes nor reorders another's history.
        for category in automatic {
            for edit in (970..<1000).reversed() { XCTAssertEqual(history.pop(for: category), "\(category)-\(edit)") }
            XCTAssertNil(history.pop(for: category))
            XCTAssertTrue(history.canUndo("manual"))
        }
        for index in (0..<30).reversed() { XCTAssertEqual(history.pop(for: "manual"), "manual-\(index)") }
        XCTAssertFalse(history.canUndo("manual"))
    }
    func testGlobalResetHistoryExpiresOnNewEditWithoutRemovingManualHistory() {
        var history = ScopedUndoHistory<String, String>()
        history.append("manual", for: "manual"); history.append("reset", for: nil)
        XCTAssertEqual(history.pop(for: "faces"), "reset")
        history.append("reset", for: nil); history.append("faces", for: "faces")
        XCTAssertEqual(history.pop(for: "manual"), "manual")
        XCTAssertNil(history.pop(for: "manual"), "A stale global Reset must not erase newer categories")
        XCTAssertEqual(history.pop(for: "faces"), "faces")
    }
    func testCachedReentryReactivatesAllWithoutNewAnalysis() {
        var selection = DetectedPrivacySelection()
        selection.activate(); selection.begin(); selection.complete(count: 3)
        XCTAssertEqual(selection.selected, [0, 1, 2])
        XCTAssertFalse(selection.needsActivationUndo)
        selection.selected.remove(1)
        XCTAssertTrue(selection.needsActivationUndo)
        selection.clear()
        XCTAssertEqual(selection.status, .completed(3))
        XCTAssertFalse(selection.isActive)
        for _ in 0..<10 {
            selection.activate()
            XCTAssertEqual(selection.selected, [0, 1, 2])
            XCTAssertTrue(selection.hasAnalyzed)
            XCTAssertFalse(selection.needsActivationUndo)
            selection.clear()
        }
    }
    func testClearDuringAnalysisDoesNotReactivateOnCompletion() {
        var selection = DetectedPrivacySelection()
        selection.activate(); selection.begin(); selection.clear(); selection.complete(count: 1)
        XCTAssertFalse(selection.isActive)
        selection.activate(); XCTAssertEqual(selection.selected, [0])
    }
    func testIndependentCategoriesAndUndoIntentPreserveOtherLayers() {
        var faces = DetectedPrivacySelection(), plates = DetectedPrivacySelection(), documents = DetectedPrivacySelection()
        faces.activate(); faces.begin(); faces.complete(count: 2)
        plates.activate(); plates.begin(); plates.complete(count: 1)
        documents.activate(); documents.begin(); documents.complete(count: 3)
        faces.clear()
        XCTAssertEqual(plates.selected, [0]); XCTAssertEqual(documents.selected, [0,1,2])
        faces.activate(); plates.clear(); plates.activate()
        XCTAssertEqual(faces.selected, [0,1]); XCTAssertEqual(plates.selected, [0])
        XCTAssertEqual(faces.status, .completed(2)); XCTAssertEqual(plates.status, .completed(1))
        faces.restoreSelection([])
        XCTAssertFalse(faces.isActive)
        var pending = DetectedPrivacySelection()
        pending.activate(); pending.begin(); pending.restoreSelection([]); pending.complete(count: 2)
        XCTAssertFalse(pending.isActive, "Undo must revoke pending activation without discarding its cache")
        pending.activate(); XCTAssertEqual(pending.selected, [0,1])
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
