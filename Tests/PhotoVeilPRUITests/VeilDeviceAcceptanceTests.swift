import XCTest

/// Physical-device acceptance uses REAL Vision. This class is excluded from VeilPR.
final class VeilDeviceAcceptanceTests: XCTestCase {
    @MainActor func testRealVisionComposedPrivacySaveAndReopen() {
        continueAfterFailure = false
        let app = XCUIApplication(), storage = UUID().uuidString
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car",
            "-veil-test-storage-id", storage, "-veil-reset-history"]
        app.launch()
        defer { app.terminate() }
        func ready() { XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 120)) }
        func counts() -> String { app.otherElements["privacySelectionCounts"].value as? String ?? "" }
        ready()
        app.buttons["mode_faces"].tap(); ready()
        XCTAssertTrue(app.buttons["face_0"].exists)
        app.buttons["mode_plate"].tap(); ready()
        XCTAssertTrue(counts().contains("faces=2,plates=1"))
        app.buttons["mode_manual"].tap(); ready()
        let canvas = app.scrollViews["photoCanvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).press(forDuration: 0.1,
            thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.48)))
        ready(); XCTAssertTrue(counts().contains("faces=2,plates=1,documents=0,rectangles=1"))
        let pixels = app.otherElements["processingComplete"].value as? String
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, pixels)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.alerts["Saved"].waitForExistence(timeout: 30)); app.alerts.buttons["OK"].tap()
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, pixels)
        let finished = XCTAttachment(screenshot: app.screenshot()); finished.name = "physical-composed-output"; finished.lifetime = .keepAlways; add(finished)
        app.terminate(); app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-test-storage-id", storage]; app.launch()
        app.buttons["gallery"].tap()
        let item = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 15)); item.tap()
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 15))
        let reopened = XCTAttachment(screenshot: app.screenshot()); reopened.name = "physical-reopened-output"; reopened.lifetime = .keepAlways; add(reopened)
    }
}
