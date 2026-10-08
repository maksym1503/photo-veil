import XCTest

/// Real editor/state/renderer/persistence, deterministic external analysis only.
final class VeilPRSmokeTests: XCTestCase {
    private var app: XCUIApplication!
    private let storage = UUID().uuidString
    override func tearDown() { app?.terminate(); app = nil; super.tearDown() }
    @MainActor private func launch(empty: Bool = false) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-analysis-fixture", "-veil-test-storage-id", storage,
            "-veil-fixture", "two-people-car", "-veil-reset-history"]
        if empty { app.launchArguments += ["-veil-empty-analysis"] }
        app.launch(); ready()
    }
    @MainActor private func ready() {
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 20), app.debugDescription)
    }
    @MainActor private func tool(_ name: String) { app.buttons["mode_\(name)"].tap(); ready() }
    @MainActor private func pixels() -> String {
        let value = app.otherElements["processingComplete"].value as? String ?? ""
        XCTAssertFalse(value.isEmpty); return value
    }
    @MainActor private func counts() -> String { app.otherElements["privacySelectionCounts"].value as? String ?? "" }
    @MainActor private func draw() {
        let canvas = app.scrollViews["photoCanvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).press(forDuration: 0.1,
            thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.48)))
        ready(); XCTAssertTrue(app.buttons["blur_region_0"].exists)
    }
    @MainActor func testComposedLayersMixedEffectsScopedClearUndoAndDone() {
        launch(); tool("faces"); let faces = pixels()
        tool("plate"); XCTAssertTrue(counts().contains("faces=2,plates=1")); XCTAssertNotEqual(pixels(), faces)
        app.buttons["effectMenu"].tap(); app.buttons["Pixelate"].tap(); ready()
        let automatic = pixels()
        tool("manual"); draw(); let combined = pixels(); XCTAssertNotEqual(combined, automatic)
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(pixels(), automatic)
        draw(); tool("faces"); app.buttons["blurAllFaces"].tap(); ready()
        XCTAssertTrue(counts().contains("faces=0,plates=1,documents=0,rectangles=1"))
        tool("manual"); tool("faces"); XCTAssertEqual(pixels(), combined)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=1,plates=1,documents=0")
        app.buttons["finalPreview"].tap(); XCTAssertFalse(app.buttons["face_0"].exists); XCTAssertEqual(pixels(), combined)
        app.buttons["finalPreview"].tap(); XCTAssertEqual(pixels(), combined)
    }
    @MainActor func testBackgroundDocumentsDetailsWholeCoverageAndCache() {
        launch(); tool("background"); let background = pixels()
        tool("documents"); XCTAssertTrue(app.buttons["document_0"].exists)
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); ready(); let details = pixels()
        XCTAssertNotEqual(details, background)
        app.buttons["documentCoverage"].tap(); app.buttons["Hide entire document"].tap(); ready(); let whole = pixels()
        XCTAssertNotEqual(whole, details)
        app.buttons["document_0"].tap(); ready(); XCTAssertEqual(pixels(), background)
        app.buttons["document_0"].tap(); ready(); XCTAssertEqual(pixels(), whole)
        XCTAssertTrue(counts().contains("background=1"))
        tool("manual"); tool("documents"); XCTAssertEqual(pixels(), whole)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=1,faces=0,plates=0,documents=1")
    }
    @MainActor func testLocalSaveReopenAndDeletionWithoutAccountOrSystemUI() {
        launch(); tool("faces"); tool("plate"); let combined = pixels()
        app.buttons["finalPreview"].tap(); app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.alerts["Saved"].waitForExistence(timeout: 20)); app.alerts.buttons["OK"].tap()
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, combined)
        app.terminate(); app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-test-storage-id", storage]; app.launch()
        app.buttons["gallery"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch.waitForExistence(timeout: 10))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 10)); app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["Delete photo"].waitForExistence(timeout: 10)); app.buttons["Delete photo"].tap()
        XCTAssertTrue(app.staticTexts["Save a finished photo to Veil. Stored on this iPhone."].waitForExistence(timeout: 10))
    }
    @MainActor func testEmptyDetectionAndStableToolbarGeometry() {
        launch(empty: true)
        let first = app.buttons["mode_background"].staticTexts.firstMatch.frame
        let last = app.buttons["mode_manual"].staticTexts.firstMatch.frame
        XCTAssertEqual(first.minX, app.frame.width - last.maxX, accuracy: 1)
        for (name, message) in [("faces", "No faces detected. Try Manual."), ("plate", "No plates detected. Try Manual."), ("documents", "No documents detected. Try Manual.")] {
            tool(name)
            XCTAssertEqual(app.staticTexts["detectionFeedback"].label, message)
            XCTAssertFalse(app.descendants(matching: .any)["detectionInProgress"].exists)
        }
    }
}
