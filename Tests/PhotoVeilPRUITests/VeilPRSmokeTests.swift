import XCTest

/// Real editor/state/renderer/persistence, deterministic external analysis only.
final class VeilPRSmokeTests: XCTestCase {
    private var app: XCUIApplication!
    private let storage = UUID().uuidString
    private var deadline: TimeInterval = 0
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // One unchanged test-plan budget covers launch, every state wait and assertions.
        // Cold hosted Core Image startup is not an individual operation performance test.
        let budget = TimeInterval(ProcessInfo.processInfo.environment["VEIL_UI_CASE_BUDGET_SECONDS"] ?? "")
        XCTAssertNotNil(budget, "Run with VeilPR test plan")
        deadline = ProcessInfo.processInfo.systemUptime + (budget ?? 0)
    }
    @MainActor private func wait(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let remaining = max(0, deadline - ProcessInfo.processInfo.systemUptime)
        XCTAssertTrue(element.waitForExistence(timeout: remaining), app.debugDescription, file: file, line: line)
    }
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
        wait(app.otherElements["processingComplete"])
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
    @MainActor func testPremiumPreviewPersistsAcrossToolsZoomUndoAndDone() {
        launch(); tool("faces")
        let rendered = pixels()
        app.buttons["finalPreview"].tap()
        for _ in 0..<1 {
            app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
            wait(app.buttons["dismissSaveNotice"]); app.buttons["dismissSaveNotice"].tap()
            XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, rendered)
        }
        let mark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        wait(mark)
        app.buttons["finalPreview"].tap()
        for name in ["plate", "documents", "background", "manual"] {
            tool(name); XCTAssertTrue(mark.exists)
        }
        app.buttons["pillar_watermark"].tap(); app.buttons["watermarkAdd"].tap(); ready()
        XCTAssertTrue(mark.exists)
        app.buttons["Undo"].tap(); ready(); XCTAssertTrue(mark.exists)
        app.buttons["pillar_metadata"].tap(); XCTAssertTrue(mark.exists)
        app.buttons["pillar_redact"].tap(); tool("faces")
        for effect in ["Pixelate", "Redact"] {
            app.buttons["effectMenu"].tap(); app.buttons[effect].tap(); ready(); XCTAssertTrue(mark.exists)
        }
        XCUIDevice.shared.press(.home); app.activate(); wait(mark)
        app.buttons["originalToggle"].tap(); XCTAssertFalse(mark.exists)
        app.buttons["originalToggle"].tap(); XCTAssertTrue(mark.exists)
        app.buttons["finalPreview"].tap()
        let canvas = app.scrollViews["photoCanvas"]
        canvas.pinch(withScale: 2, velocity: 1); canvas.swipeUp()
        XCTAssertTrue(mark.exists)
        XCTAssertTrue(canvas.frame.intersects(mark.frame))
        app.buttons["unlockCleanExports"].tap()
        wait(app.buttons["subscriptionClose"]); app.buttons["subscriptionClose"].tap()
        XCTAssertTrue(mark.exists)
        app.terminate(); launch(); wait(mark)
    }

    @MainActor func testAutomaticRegionMoveResizeScopedUndoAndDocumentCoverage() {
        launch()
        for (toolName, identifier) in [("faces", "face_0"), ("plate", "plate_0"), ("documents", "document_0")] {
            tool(toolName)
            let region = app.buttons[identifier]
            wait(region)
            let before = region.value as? String
            let neighbor = app.buttons[toolName == "faces" ? "face_1" : "document_1"]
            let neighborBefore = neighbor.exists ? neighbor.value as? String : nil
            let fingerprint = pixels()
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "vail11-" + toolName; capture.lifetime = .keepAlways; add(capture)
            let center = region.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            center.press(forDuration: 0.1, thenDragTo: center.withOffset(CGVector(dx: 24, dy: 18)))
            ready()
            XCTAssertNotEqual(region.value as? String, before)
            let moved = (region.value as? String ?? "").split(separator: ",")
            let originalRect = (before ?? "").split(separator: ",")
            XCTAssertEqual(Array(moved.suffix(2)), Array(originalRect.suffix(2)), "Body drag preserves size")
            XCTAssertNotEqual(Array(moved.prefix(2)), Array(originalRect.prefix(2)), "Body drag changes position")
            XCTAssertNotEqual(pixels(), fingerprint)
            if let neighborBefore { XCTAssertEqual(neighbor.value as? String, neighborBefore) }
            app.buttons["Undo"].tap(); ready()
            XCTAssertEqual(region.value as? String, before)
            XCTAssertEqual(pixels(), fingerprint)
            region.tap(); ready(); XCTAssertNotEqual(pixels(), fingerprint)
            region.tap(); ready(); XCTAssertEqual(pixels(), fingerprint)
            let corner = region.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
            corner.press(forDuration: 0.1, thenDragTo: corner.withOffset(CGVector(dx: 18, dy: 16)))
            ready()
            XCTAssertNotEqual(region.value as? String, before)
            let resized = (region.value as? String ?? "").split(separator: ",")
            XCTAssertEqual(Array(resized.prefix(2)), Array(originalRect.prefix(2)), "Corner drag preserves origin")
            XCTAssertNotEqual(Array(resized.suffix(2)), Array(originalRect.suffix(2)), "Corner drag changes size")
            let adjusted = pixels()
            if toolName == "documents" {
                app.buttons["documentCoverage"].tap(); app.buttons["Hide entire document"].tap(); ready()
                app.buttons["documentCoverage"].tap(); app.buttons["Hide all details"].tap(); ready()
                XCTAssertEqual(pixels(), adjusted)
            }
            app.buttons["finalPreview"].tap(); ready(); XCTAssertEqual(pixels(), adjusted)
            app.buttons["finalPreview"].tap()
        }
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=1,plates=1,documents=1")
        let canvas = app.scrollViews["photoCanvas"]
        canvas.pinch(withScale: 2, velocity: 1)
        ready()
        let region = app.buttons["document_0"]
        let before = region.value as? String
        let center = region.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.1, thenDragTo: center.withOffset(CGVector(dx: 20, dy: 20)))
        ready(); XCTAssertNotEqual(region.value as? String, before)
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(region.value as? String, before)
        let adjusted = pixels()
        app.buttons["finalPreview"].tap()
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        wait(app.buttons["dismissSaveNotice"])
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, adjusted)
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
        app.buttons["finalPreview"].tap()
        let summary = app.buttons["metadataReviewChange"]
        wait(summary); XCTAssertEqual(summary.value as? String, "Keep metadata")
        XCTAssertFalse(app.buttons["metadataKeep"].exists)
        summary.tap()
        let keep = app.buttons["metadataKeep"]
        wait(keep); XCTAssertTrue(keep.isSelected)
        app.buttons["metadataRemove"].tap()
        XCTAssertTrue(app.buttons["metadataRemove"].isSelected)
        keep.tap(); app.buttons["finalPreview"].tap()
        XCTAssertEqual(summary.value as? String, "Keep metadata")
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        wait(app.buttons["dismissSaveNotice"]); app.buttons["dismissSaveNotice"].tap()
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, combined)
        app.terminate(); app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-test-storage-id", storage]; app.launch()
        app.buttons["gallery"].tap()
        wait(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch)
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch.tap()
        wait(app.staticTexts["Exports keep supported metadata"])
        wait(app.buttons["Delete"]); app.buttons["Delete"].tap()
        wait(app.buttons["Delete photo"]); app.buttons["Delete photo"].tap()
        wait(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."])
    }
    @MainActor func testWatermarkCompositionScopedUndoAndPrivacyChoices() {
        launch(); tool("faces"); let covered = pixels()
        app.buttons["pillar_watermark"].tap()
        wait(app.buttons["watermarkAdd"]); app.buttons["watermarkAdd"].tap(); ready()
        let marked = pixels(); XCTAssertNotEqual(marked, covered)
        app.buttons["watermarkRepeat"].tap(); ready(); XCTAssertNotEqual(pixels(), marked)
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(pixels(), marked)
        let position = app.otherElements["watermarkPosition"]
        wait(position)
        position.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.1,
            thenDragTo: position.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.6)))
        ready(); XCTAssertNotEqual(pixels(), marked)
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(pixels(), marked)
        app.buttons["pillar_redact"].tap()
        app.buttons["blurAllFaces"].tap(); ready(); let watermarkOnly = pixels()
        XCTAssertNotEqual(watermarkOnly, marked)
        app.buttons["pillar_metadata"].tap()
        XCTAssertFalse(app.buttons["Undo"].isEnabled, "Metadata focus cannot undo unrelated redactions")
        let keep = app.buttons["metadataKeep"]
        wait(keep); XCTAssertTrue(keep.isSelected)
        app.buttons["metadataRemove"].tap()
        app.buttons["pillar_watermark"].tap()
        app.buttons["watermarkRemove"].tap(); ready()
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(pixels(), watermarkOnly)
        app.buttons["More editing actions"].tap(); app.buttons["Reset edits"].tap(); ready()
        XCTAssertNotEqual(pixels(), watermarkOnly)
        app.buttons["Undo"].tap(); ready(); XCTAssertEqual(pixels(), watermarkOnly)
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Remove metadata")
        XCTAssertFalse(app.buttons["pillar_metadata"].exists)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        wait(app.buttons["dismissSaveNotice"]); app.buttons["dismissSaveNotice"].tap()
        // No synthetic evidence opt-in: custom watermark pixels must not be dumped.
        app.buttons["Close photo"].tap()
        app.launchArguments = ["-veil-ui-testing", "-veil-analysis-fixture", "-veil-test-storage-id", storage, "-veil-fixture", "two-people-car"]
        app.terminate(); app.launch(); ready()
        app.buttons["pillar_watermark"].tap(); wait(app.buttons["watermarkAdd"])
        XCTAssertFalse(app.buttons["watermarkRemove"].exists, "New sessions must not retain watermark content")
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
