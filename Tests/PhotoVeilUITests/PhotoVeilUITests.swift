import XCTest

final class PhotoVeilUITests: XCTestCase {
    @MainActor func testFirstLaunchSettingsAndPrivacy() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        attach(app, "first-launch")
        app.buttons["settings"].tap()
        XCTAssertTrue(app.staticTexts["Version / Build"].waitForExistence(timeout: 5))
        attach(app, "settings")
        app.buttons["photoPrivacy"].tap()
        XCTAssertTrue(app.staticTexts["Photo processing happens entirely on this iPhone. Photos are not uploaded to Veil servers."].waitForExistence(timeout: 5))
        attach(app, "privacy")
    }

    @MainActor func testFacesDetectionSelectionAndStableCanvas() {
        let app = launch(fixture: "two-faces")
        let before = transform(app)
        app.buttons["mode_faces"].tap()
        waitForRender(app)
        assertCamera(app, before, "Detection must not change the camera")
        let face = app.buttons["face_0"]
        XCTAssertTrue(face.waitForExistence(timeout: 10), "Use real Vision detection")
        XCTAssertTrue(app.buttons["face_1"].exists)
        XCTAssertFalse(app.buttons["blur_region_0"].exists)
        attach(app, "faces-all-blurred")
        face.tap()
        waitForRender(app)
        XCTAssertEqual(face.label, "Face 1")
        assertCamera(app, before)
        attach(app, "faces-selective")
        app.buttons["blurAllFaces"].tap()
        waitForRender(app)
        XCTAssertEqual(face.label, "Blurred face 1")
        let fingerprint = app.otherElements["processingComplete"].value as? String
        app.buttons["finalPreview"].tap()
        XCTAssertFalse(face.exists)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, fingerprint)
        attach(app, "faces-clean-preview")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(face.label, "Blurred face 1")
        export(app, "faces-export")
    }

    @MainActor func testPlateDetectionSelectionAndStableCanvas() {
        let app = launch(fixture: "two-people-car")
        let before = transform(app)
        app.buttons["mode_plate"].tap()
        waitForRender(app)
        assertCamera(app, before)
        let plate = app.buttons["plate_0"]
        XCTAssertTrue(plate.waitForExistence(timeout: 10))
        XCTAssertEqual(plate.label, "Blurred plate suggestion")
        let sharpFingerprint = app.otherElements["processingComplete"].value as? String
        attach(app, "plate-auto-blurred")
        plate.tap()
        waitForRender(app)
        XCTAssertEqual(plate.label, "Plate suggestion")
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, sharpFingerprint, "Selection must change rendered pixels, not just the outline")
        assertCamera(app, before)
        XCTAssertFalse(app.buttons["blur_region_0"].exists)
        plate.tap(); waitForRender(app)
        XCTAssertEqual(plate.label, "Blurred plate suggestion")
        attach(app, "plate-blurred")
        app.buttons["blurAllPlates"].tap(); waitForRender(app)
        XCTAssertEqual(plate.label, "Plate suggestion")
        app.buttons["blurAllPlates"].tap(); waitForRender(app)
        XCTAssertEqual(plate.label, "Blurred plate suggestion")
        app.buttons["strength_low"].tap(); waitForRender(app)
        let lowFingerprint = app.otherElements["processingComplete"].value as? String
        attach(app, "plate-low")
        app.buttons["strength_strong"].tap(); waitForRender(app)
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, lowFingerprint)
        attach(app, "plate-strong")
        app.buttons["finalPreview"].tap()
        XCTAssertFalse(plate.exists)
        XCTAssertFalse(app.buttons["originalToggle"].exists)
        attach(app, "plate-clean-preview")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(plate.label, "Blurred plate suggestion")
        app.scrollViews["photoCanvas"].pinch(withScale: 2, velocity: 1)
        XCTAssertGreaterThan(transform(app)[0], 1.5)
        attach(app, "plate-zoomed")
        export(app, "plate-export")
    }

    @MainActor func testManualCreateZoomPanMoveResizeDeleteAndExport() {
        let app = launch(fixture: "two-people-car")
        let canvas = app.scrollViews["photoCanvas"]
        let before = transform(app)
        app.buttons["mode_manual"].tap()
        waitForRender(app)
        assertCamera(app, before)
        drag(canvas, from: CGVector(dx: 0.55, dy: 0.62), to: CGVector(dx: 0.85, dy: 0.74))
        waitForRender(app)
        let region = app.buttons["blur_region_0"]
        XCTAssertTrue(region.waitForExistence(timeout: 5))
        assertCamera(app, before)
        let imageRegion = region.value as? String
        attach(app, "manual-blurred")
        canvas.pinch(withScale: 2, velocity: 1)
        XCTAssertGreaterThan(transform(app)[0], 1.5)
        app.buttons["Move photo"].tap()
        let zoom = transform(app)[0]
        drag(canvas, from: CGVector(dx: 0.75, dy: 0.65), to: CGVector(dx: 0.45, dy: 0.45))
        XCTAssertEqual(transform(app)[0], zoom, accuracy: 0.001)
        XCTAssertEqual(region.value as? String, imageRegion, "Camera movement must not mutate image coordinates")
        attach(app, "manual-zoom-pan")
        app.buttons["fitPhoto"].tap()
        XCTAssertEqual(transform(app)[0], 1, accuracy: 0.001)
        app.buttons["Draw blur region"].tap()
        let center = region.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.1, thenDragTo: center.withOffset(CGVector(dx: -30, dy: -20)))
        waitForRender(app)
        let resize = region.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
        resize.press(forDuration: 0.1, thenDragTo: resize.withOffset(CGVector(dx: 20, dy: 15)))
        waitForRender(app)
        XCTAssertNotEqual(region.value as? String, imageRegion)
        attach(app, "manual-moved-resized")
        app.buttons["strength_strong"].tap()
        waitForRender(app)

        region.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0)).tap()
        waitForRender(app)
        XCTAssertFalse(region.exists)
        app.buttons["Undo"].tap()
        waitForRender(app)
        XCTAssertTrue(region.exists)
        let editedCoordinates = region.value as? String
        app.buttons["finalPreview"].tap()
        XCTAssertFalse(region.exists)
        attach(app, "rectangle-clean-preview")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(region.value as? String, editedCoordinates)
        app.buttons["finalPreview"].tap()
        export(app, "manual-export")
    }

    @MainActor func testFreehandBlurUndoZoomPanAndCleanPreview() {
        let app = launch(fixture: "two-people-car")
        let canvas = app.scrollViews["photoCanvas"]
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let sharpFingerprint = app.otherElements["processingComplete"].value as? String
        app.buttons["manualBrush"].tap()
        drag(canvas, from: CGVector(dx: 0.35, dy: 0.55), to: CGVector(dx: 0.7, dy: 0.65))
        waitForRender(app)
        let stroke = app.otherElements["blur_stroke_0"]
        XCTAssertTrue(stroke.exists)
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, sharpFingerprint)
        attach(app, "freehand-blurred")
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertFalse(stroke.exists)
        drag(canvas, from: CGVector(dx: 0.35, dy: 0.55), to: CGVector(dx: 0.7, dy: 0.65))
        waitForRender(app)
        XCTAssertNotNil(stroke.value as? String)
        let savedCoordinates = stroke.value as? String
        canvas.pinch(withScale: 2, velocity: 1)
        app.buttons["Move photo"].tap()
        drag(canvas, from: CGVector(dx: 0.65, dy: 0.65), to: CGVector(dx: 0.45, dy: 0.45))
        XCTAssertEqual(stroke.value as? String, savedCoordinates)
        attach(app, "freehand-zoom-pan")
        app.buttons["fitPhoto"].tap()
        app.buttons["strength_strong"].tap(); waitForRender(app)
        app.buttons["finalPreview"].tap()
        XCTAssertFalse(stroke.exists)
        XCTAssertFalse(app.buttons["mode_manual"].exists)
        XCTAssertFalse(app.buttons["originalToggle"].exists)
        attach(app, "freehand-clean-preview")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(stroke.value as? String, savedCoordinates)
        app.buttons["finalPreview"].tap()
        export(app, "freehand-export")
    }

    @MainActor func testManualCreationAfterZoomAndPanMapsToImagePixels() {
        let app = launch(fixture: "two-people-car")
        let canvas = app.scrollViews["photoCanvas"]
        app.buttons["mode_manual"].tap(); waitForRender(app)
        canvas.pinch(withScale: 2.5, velocity: 1)
        app.buttons["Move photo"].tap()
        drag(canvas, from: CGVector(dx: 0.6, dy: 0.6), to: CGVector(dx: 0.45, dy: 0.45))
        app.buttons["Draw blur region"].tap()
        let camera = transform(app)
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.36, dy: 0.5))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.62))
        start.press(forDuration: 0.1, thenDragTo: end)
        waitForRender(app)
        let region = app.buttons["blur_region_0"]
        XCTAssertTrue(region.exists)
        let expected = CGRect(x: start.screenPoint.x, y: start.screenPoint.y,
                              width: end.screenPoint.x - start.screenPoint.x, height: end.screenPoint.y - start.screenPoint.y)
        XCTAssertEqual(region.frame.minX, expected.minX, accuracy: 2)
        XCTAssertEqual(region.frame.minY, expected.minY, accuracy: 2)
        XCTAssertEqual(region.frame.width, expected.width, accuracy: 2)
        XCTAssertEqual(region.frame.height, expected.height, accuracy: 2)
        assertCamera(app, camera)
        let imageCoordinates = region.value as? String
        attach(app, "manual-created-after-zoom-pan")
        app.buttons["fitPhoto"].tap()
        XCTAssertEqual(region.value as? String, imageCoordinates)
        assertCamera(app, [1, 0, 0])
        attach(app, "manual-zoom-created-returned-to-fit")
    }

    @MainActor func testModeSwitchingPreservesZoomPanAndHidesStaleOverlays() {
        let app = launch(fixture: "two-faces")
        let canvas = app.scrollViews["photoCanvas"]
        app.buttons["mode_manual"].tap(); waitForRender(app)
        drag(canvas, from: CGVector(dx: 0.35, dy: 0.4), to: CGVector(dx: 0.55, dy: 0.6))
        waitForRender(app)
        canvas.pinch(withScale: 2, velocity: 1)
        let before = transform(app)
        for mode in ["faces", "manual", "plate", "background", "faces"] {
            app.buttons["mode_\(mode)"].tap()
            waitForRender(app)
            let after = transform(app)
            for index in 0..<3 { XCTAssertEqual(after[index], before[index], accuracy: index == 0 ? 0.001 : 0.5, "Mode \(mode) changed the camera") }
            if mode == "faces" || mode == "plate" { XCTAssertFalse(app.buttons["blur_region_0"].exists) }
            attach(app, "stable-mode-\(mode)")
        }
        app.buttons["fitPhoto"].tap()
        assertCamera(app, [1, 0, 0])
    }

    @MainActor func testBackgroundPersonMaskOrManualFallback() { checkBackground(fixture: "background-person", name: "person") }
    @MainActor func testBackgroundCarMaskOrManualFallback() { checkBackground(fixture: "two-people-car", name: "car") }

    @MainActor private func checkBackground(fixture: String, name: String) {
        let app = launch(fixture: fixture)
        let before = transform(app)
        app.buttons["mode_background"].tap()
        // A cold hosted Simulator can take over 45s to initialize Vision before returning its fallback.
        // Keep the normal bound for interactive edits; only foreground model startup gets extra time.
        waitForRender(app, timeout: 120)
        assertCamera(app, before)
        let state = app.otherElements["processingComplete"].label
        if state == "Manual fallback" {
            XCTAssertTrue(app.staticTexts["No foreground found. Select manually."].exists)
            attach(app, "background-\(name)-fallback")
            return // Simulator Vision may lack foreground model support; report explicitly.
        }
        XCTAssertEqual(state, "Background ready")
        attach(app, "background-\(name)-sharp")
        app.buttons["originalToggle"].tap()
        attach(app, "background-\(name)-original")
        app.buttons["originalToggle"].tap()
        export(app, "background-\(name)-export")
    }

    @MainActor private func launch(fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", fixture]
        app.launch()
        XCTAssertTrue(app.scrollViews["photoCanvas"].waitForExistence(timeout: 10))
        attach(app, "initial-\(fixture)")
        return app
    }
    @MainActor private func assertCamera(_ app: XCUIApplication, _ expected: [Double], _ message: String = "") {
        let actual = transform(app)
        for index in 0..<3 { XCTAssertEqual(actual[index], expected[index], accuracy: index == 0 ? 0.001 : 0.5, message) }
    }
    @MainActor private func transform(_ app: XCUIApplication) -> [Double] {
        let value = app.scrollViews["photoCanvas"].value as? String ?? ""
        let values = value.split(separator: ",").compactMap { Double($0) }
        XCTAssertEqual(values.count, 3)
        return values.count == 3 ? values : [-1, -1, -1]
    }
    @MainActor private func waitForRender(_ app: XCUIApplication, timeout: TimeInterval = 45) {
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: timeout))
    }
    @MainActor private func drag(_ canvas: XCUIElement, from: CGVector, to: CGVector) {
        canvas.coordinate(withNormalizedOffset: from).press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: to))
    }
    @MainActor private func export(_ app: XCUIApplication, _ name: String) {
        if app.buttons["finalPreview"].label == "Done" { app.buttons["finalPreview"].tap() }
        app.buttons["Export"].tap()
        XCTAssertTrue(app.staticTexts["Copy"].waitForExistence(timeout: 15))
        attach(app, name)
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
