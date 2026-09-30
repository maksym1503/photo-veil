import XCTest

final class PhotoVeilUITests: XCTestCase {
    @MainActor func testPhotoCanvasZoomAndManualRegionEditing() {
        let app = launch(mode: "manual")
        let canvas = app.scrollViews["photoCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        attachScreenshot(app, name: "photo-loaded")

        canvas.pinch(withScale: 2.5, velocity: 1)
        XCTAssertTrue(app.buttons["fitPhoto"].waitForExistence(timeout: 5))
        attachScreenshot(app, name: "photo-zoomed")

        app.buttons["Move photo"].tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.56))
            .press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.47, dy: 0.48)))
        app.buttons["Draw blur region"].tap()
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.38, dy: 0.42))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.58, dy: 0.56))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(app.descendants(matching: .any)["blur_region_0"].waitForExistence(timeout: 5))
        attachScreenshot(app, name: "manual-region-created")

        let strength = app.buttons["strength_strong"]
        if strength.exists { strength.tap() }
        app.buttons["Undo"].tap()
        app.buttons["Undo"].tap()
        app.buttons["More editing actions"].tap()
        app.buttons["Reset edits"].tap()
        attachScreenshot(app, name: "manual-reset")
    }

    @MainActor func testFaceSelectionAndAllFacesControl() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-mode", "faces", "-veil-test-faces"]
        app.launch()
        let canvas = app.scrollViews["photoCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        let firstFace = app.descendants(matching: .any)["face_0"].firstMatch
        XCTAssertTrue(firstFace.waitForExistence(timeout: 10), "The deterministic face overlay fixture should appear")
        let secondFace = app.descendants(matching: .any)["face_1"].firstMatch
        XCTAssertTrue(secondFace.waitForExistence(timeout: 5))
        attachScreenshot(app, name: "faces-detected")

        firstFace.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "face_0").firstMatch.label.contains("Face 1"))
        attachScreenshot(app, name: "one-face-selected")
        app.buttons["blurAllFaces"].tap()
        attachScreenshot(app, name: "all-faces-blurred")
    }

    @MainActor func testBackgroundKeepsForegroundSharpAndComparisonWorks() {
        let app = launch(mode: "background")
        XCTAssertTrue(app.scrollViews["photoCanvas"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.activityIndicators["Processing"].exists)
        XCTAssertEqual(app.otherElements["processingComplete"].label, "Background ready")
        XCTAssertFalse(app.staticTexts["Subject stays clear. Hold photo to compare original."].exists)
        XCTAssertTrue(app.buttons["originalToggle"].exists)
        attachScreenshot(app, name: "background-person-sharp")
        app.buttons["originalToggle"].tap()
        attachScreenshot(app, name: "background-original-comparison")
    }

    @MainActor func testPlateSuggestionSelectionPreviewAndExport() {
        let app = launch(mode: "plate")
        XCTAssertTrue(app.scrollViews["photoCanvas"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.activityIndicators["Processing"].exists)
        let plate = app.descendants(matching: .any)["plate_0"].firstMatch
        XCTAssertTrue(plate.waitForExistence(timeout: 10), "The generated fixture should produce a plate suggestion")
        attachScreenshot(app, name: "plate-suggestion")
        plate.tap()
        attachScreenshot(app, name: "plate-blurred")
        app.buttons["Export"].tap()
        XCTAssertTrue(app.otherElements.firstMatch.waitForExistence(timeout: 10))
        attachScreenshot(app, name: "export-sheet")
    }

    @MainActor private func launch(mode: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-mode", mode]
        app.launch()
        return app
    }

    @MainActor private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
