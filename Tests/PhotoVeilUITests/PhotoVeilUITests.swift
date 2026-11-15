import XCTest

final class PhotoVeilUITests: XCTestCase {
    /// All photos are fictional; analysis, controls, renders and saves are the real app.
    @MainActor func testRefinedEditorialAndPreviewJourney() { captureFinalEditorialJourney(appearance: "Light") }
    @MainActor func testRefinedEditorialDarkAppearanceJourney() { captureFinalEditorialJourney(appearance: "Dark") }

    @MainActor private func captureFinalEditorialJourney(appearance: String) {
        let app = XCUIApplication()
        let scope = UUID().uuidString
        func load(_ fixture: String, mode: String) {
            app.terminate()
            app.launchArguments = ["-veil-ui-testing", "-veil-fixture", fixture, "-veil-mode", mode, "-veil-test-storage-id", scope, "-veil-legacy-usage", "0", "-AppleInterfaceStyle", appearance]
            app.launch(); waitForRender(app, timeout: 120)
        }
        func capture(_ name: String) { attach(app, "final-" + appearance.lowercased() + "-" + name) }
        func save() {
            app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
            XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 20))
            app.buttons["dismissSaveNotice"].tap()
        }
        func rectValue(_ element: XCUIElement) -> [Double] {
            let values = (element.value as? String ?? "").split(separator: ",").compactMap { Double($0) }
            XCTAssertEqual(values.count, 4, "Selected detected region must expose normalized geometry")
            return values
        }
        func move(_ region: XCUIElement) {
            let before = rectValue(region)
            let from = region.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: -14, dy: -8)))
            waitForRender(app)
            let after = rectValue(region)
            XCTAssertNotEqual(Array(after.prefix(2)), Array(before.prefix(2)), "Move must change the detected region origin")
            XCTAssertEqual(Array(after.suffix(2)), Array(before.suffix(2)), "Move must preserve detected region dimensions")
        }
        func resize(_ region: XCUIElement) {
            let before = rectValue(region)
            let from = region.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
            from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: 30, dy: 20)))
            waitForRender(app)
            let after = rectValue(region)
            XCTAssertEqual(Array(after.prefix(2)), Array(before.prefix(2)), "Resize must preserve detected region origin")
            XCTAssertNotEqual(Array(after.suffix(2)), Array(before.suffix(2)), "Resize must change detected region dimensions")
        }
        load("marketing-cafe", mode: "faces")
        XCTAssertTrue(app.buttons["face_1"].exists)
        capture("01-faces-after")
        app.buttons["originalToggle"].tap(); capture("01-faces-before"); app.buttons["originalToggle"].tap()
        load("two-people-car", mode: "plate")
        XCTAssertTrue(app.buttons["plate_0"].exists)
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app)
        app.scrollViews["photoCanvas"].pinch(withScale: 1.8, velocity: 1)
        waitForRender(app)
        capture("02-plates-after")
        app.buttons["originalToggle"].tap(); capture("02-plates-before"); app.buttons["originalToggle"].tap()
        load("marketing-coast", mode: "manual")
        app.buttons["pillar_metadata"].tap(); app.buttons["metadataRemove"].tap()
        XCTAssertTrue(app.buttons["metadataRemove"].isSelected)
        capture("03-location-after")
        load("marketing-card", mode: "documents")
        let detected = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "document_")).allElementsBoundByIndex
        XCTAssertFalse(detected.isEmpty, "Real Vision must detect the photographed document; no manual fallback")
        guard let target = detected.min(by: { a, b in
            let ar = rectValue(a), br = rectValue(b)
            guard ar.count == 4, br.count == 4 else { return false }
            return abs(ar[1] + ar[3] / 2 - 0.475) < abs(br[1] + br[3] / 2 - 0.475)
        }) else { return }
        let targetID = target.identifier
        app.buttons["documentCoverage"].tap(); app.buttons["Clear All"].tap(); waitForRender(app)
        let region = app.buttons[targetID]; region.tap(); waitForRender(app)
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app)
        let initialRect = rectValue(region)
        let initialPixels = app.otherElements["processingComplete"].value as? String
        capture("04-documents-detected")
        move(region)
        XCTAssertNotEqual(rectValue(region), initialRect)
        capture("04-documents-moved")
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(rectValue(region), initialRect)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, initialPixels)
        move(region); let movedRect = rectValue(region)
        resize(region); XCTAssertNotEqual(rectValue(region), movedRect)
        app.buttons["Undo"].tap(); waitForRender(app); XCTAssertEqual(rectValue(region), movedRect)
        resize(region)
        XCTAssertTrue((app.otherElements["analysisCounts"].value as? String ?? "").contains("documents=1"))
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String ?? "").contains("documents=1,rectangles=0,strokes=0"))
        capture("04-documents-after")
        app.buttons["originalToggle"].tap(); capture("04-documents-before"); app.buttons["originalToggle"].tap()
        load("two-faces", mode: "faces")
        XCTAssertTrue(app.buttons["face_1"].exists)
        app.buttons["finalPreview"].tap(); capture("05-share-after")
        // Consume actual successful exports; no quota or entitlement fixture override.
        save()
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        let item = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 10)); item.tap()
        let galleryPhoto = app.descendants(matching: .any).matching(identifier: "galleryProcessedPhoto").firstMatch
        XCTAssertTrue(galleryPhoto.waitForExistence(timeout: 10))
        capture("gallery-clean")
        load("two-faces", mode: "faces"); app.buttons["finalPreview"].tap(); save()
        let mark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10))
        load("marketing-cafe", mode: "faces")
        XCTAssertTrue(mark.waitForExistence(timeout: 10)); capture("preview-light")
        load("marketing-night", mode: "faces")
        XCTAssertTrue(app.buttons["face_1"].exists)
        XCTAssertTrue(mark.waitForExistence(timeout: 10)); capture("preview-dark")
        let unlock = app.buttons["unlockCleanExports"]
        XCTAssertTrue(unlock.exists); XCTAssertTrue(unlock.isHittable)
        XCTAssertGreaterThanOrEqual(unlock.frame.width, 44)
        XCTAssertGreaterThanOrEqual(unlock.frame.height, 44)
        let frames = ["appearance": appearance, "unlockWidth": String(Double(unlock.frame.width)), "unlockHeight": String(Double(unlock.frame.height)), "unlockHittable": String(unlock.isHittable)]
        let frameEvidence = XCTAttachment(string: frames.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: "\n"))
        frameEvidence.name = "final-" + appearance.lowercased() + "-accessibility-frames"
        frameEvidence.lifetime = .keepAlways; add(frameEvidence)
        unlock.tap()
        XCTAssertTrue(app.buttons["subscriptionRestore"].waitForExistence(timeout: 15))
        app.buttons["subscriptionClose"].tap()
        XCTAssertTrue(mark.exists)
        app.terminate()
    }

    /// Marketing evidence uses actual Vision results, never substituted rectangles.
    @MainActor func testNextReleaseFaceMarketingCapture() {
        let app = launch(fixture: "two-people-car")
        app.buttons["mode_faces"].tap(); waitForRender(app, timeout: 120)
        XCTAssertTrue(app.buttons["face_0"].exists)
        XCTAssertTrue(app.buttons["face_1"].exists)
        attach(app, "vail11-real-faces")
        app.buttons["originalToggle"].tap()
        attach(app, "vail11-real-faces-before")
        app.buttons["originalToggle"].tap()
        app.terminate()
    }

    /// Real production interaction/rendering with an original, rights-controlled synthetic document.
    /// Capture at native simulator resolution; no UI is reconstructed or composited.
    @MainActor func testAppStoreScreenshotJourney() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-reset-history"]
        app.launch()
        let hero = app.otherElements["privacyDemonstration"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        hero.tap() // Stop automatic cycling through the existing user interaction.
        for _ in 0..<4 {
            if hero.value as? String == "Visual privacy" || hero.value as? String == "Privacy tools preview" { break }
            hero.tap()
        }
        XCTAssertTrue(app.buttons["choosePhoto"].isHittable)
        attach(app, "appstore-01-home")
        app.terminate()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "release-owned-sample", "-veil-mode", "manual", "-veil-reset-history", "-veil-synthetic-watermark-evidence"]
        app.launch(); waitForRender(app)
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app)
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.10, dy: 0.50), to: CGVector(dx: 0.90, dy: 0.60))
        waitForRender(app)
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String)?.contains("rectangles=1") == true)
        attach(app, "appstore-02-redact")
        app.buttons["pillar_metadata"].tap()
        XCTAssertTrue(app.buttons["metadataKeep"].isSelected)
        attach(app, "appstore-03-metadata-keep")
        app.buttons["pillar_watermark"].tap(); app.buttons["watermarkAdd"].tap(); waitForRender(app)
        app.buttons["watermarkText"].tap()
        let field = app.descendants(matching: .any).matching(identifier: "watermarkTextField").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        app.buttons["watermarkClearText"].tap(); field.typeText("PRIVATE COPY")
        app.buttons["watermarkApplyText"].tap(); waitForRender(app)
        app.buttons["watermarkStyle"].tap(); app.buttons["Stamp"].tap(); waitForRender(app)
        attach(app, "appstore-04-watermark")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Keep metadata")
        XCTAssertTrue(app.buttons["saveMenu"].isHittable); XCTAssertTrue(app.buttons["export"].isHittable)
        attach(app, "appstore-05-review")
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 20))
        app.buttons["dismissSaveNotice"].tap()
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        XCTAssertTrue(app.staticTexts["Exports keep supported metadata"].exists)
        attach(app, "appstore-06-gallery")
        // Audit the second real saved-file branch without rewriting the Keep copy.
        app.terminate()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "release-owned-sample", "-veil-mode", "manual"]
        app.launch(); waitForRender(app)
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app)
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.10, dy: 0.50), to: CGVector(dx: 0.90, dy: 0.60))
        waitForRender(app)
        app.buttons["pillar_metadata"].tap(); app.buttons["metadataRemove"].tap()
        app.buttons["pillar_watermark"].tap(); app.buttons["watermarkAdd"].tap(); waitForRender(app)
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Remove metadata")
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 20))
        attach(app, "qa-native-remove-export")
    }

    @MainActor func testV43ToolbarGeometry() {
        let app = launch(fixture: "two-people-car")
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let first = app.buttons["mode_background"].frame
        let last = app.buttons["mode_manual"].frame
        let leftText = app.buttons["mode_background"].staticTexts.firstMatch.frame
        let rightText = app.buttons["mode_manual"].staticTexts.firstMatch.frame
        print("V43 geometry buttons=\(first),\(last) labels=\(leftText),\(rightText)")
        XCTAssertEqual(leftText.minX, app.frame.width - rightText.maxX, accuracy: 1)
        attach(app, "v43-toolbar")
    }

    @MainActor func testV43ComposedPrivacyWorkflowAndScopedUndo() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-reset-history", "-veil-test-storage-id", UUID().uuidString, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        func counts() -> String { app.otherElements["privacySelectionCounts"].value as? String ?? "" }
        func fingerprint() -> String { app.otherElements["processingComplete"].value as? String ?? "" }
        app.buttons["mode_faces"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["face_0"].exists)
        let facesOnly = fingerprint()
        app.buttons["mode_plate"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["plate_0"].exists)
        let both = fingerprint(), bothCounts = counts()
        XCTAssertNotEqual(both, facesOnly)
        XCTAssertTrue(bothCounts.contains("faces=2,plates=1"))
        attach(app, "v43-faces-and-plates")
        app.buttons["mode_faces"].tap(); waitForRender(app)
        XCTAssertEqual(fingerprint(), both)
        app.buttons["blurAllFaces"].tap(); waitForRender(app)
        XCTAssertTrue(counts().contains("faces=0,plates=1"))
        let platesOnly = fingerprint()
        XCTAssertNotEqual(platesOnly, both)
        app.buttons["mode_manual"].tap(); app.buttons["mode_faces"].tap(); waitForRender(app)
        XCTAssertEqual(fingerprint(), both)
        XCTAssertEqual(counts(), bothCounts)
        app.buttons["strength_strong"].tap(); waitForRender(app)
        app.buttons["mode_plate"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["strength_medium"].isSelected)
        app.buttons["effectMenu"].tap(); app.buttons["Pixelate"].tap(); waitForRender(app)
        app.buttons["mode_manual"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["strength_medium"].isSelected)
        XCTAssertTrue(app.buttons["effectMenu"].label.contains("Blur"))
        let beforeManual = fingerprint()
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.35, dy: 0.3), to: CGVector(dx: 0.55, dy: 0.45)); waitForRender(app)
        XCTAssertTrue(counts().contains("faces=2,plates=1,documents=0,rectangles=1"))
        let allThree = fingerprint()
        XCTAssertNotEqual(allThree, beforeManual)
        attach(app, "v43-mixed-three-layers")
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(fingerprint(), beforeManual)
        XCTAssertTrue(counts().contains("faces=2,plates=1,documents=0,rectangles=0"))
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.35, dy: 0.3), to: CGVector(dx: 0.55, dy: 0.45)); waitForRender(app)
        app.buttons["mode_faces"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["strength_strong"].isSelected)
        app.buttons["blurAllFaces"].tap(); waitForRender(app)
        XCTAssertTrue(counts().contains("faces=0,plates=1,documents=0,rectangles=1"))
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertTrue(counts().contains("faces=2,plates=1,documents=0,rectangles=1"))
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=1,plates=1,documents=0")
        let final = fingerprint()
        app.buttons["finalPreview"].tap(); attach(app, "v43-three-layers-done")
        XCTAssertEqual(fingerprint(), final)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        XCTAssertEqual(fingerprint(), final)
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, final, "Gallery export must exactly match the live composition")
        export(app, "v43-three-layers-share")
    }

    @MainActor func testV43ManualUndoCannotRestoreStaleGlobalReset() {
        let app = launch(fixture: "two-people-car")
        app.buttons["mode_faces"].tap(); waitForRender(app)
        app.buttons["More editing actions"].tap(); app.buttons["Reset edits"].tap(); waitForRender(app)
        app.buttons["mode_plate"].tap(); waitForRender(app)
        app.buttons["mode_manual"].tap(); waitForRender(app)
        XCTAssertFalse(app.buttons["Undo"].isEnabled)
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String)?.contains("faces=0,plates=1") == true)
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.35, dy: 0.3), to: CGVector(dx: 0.55, dy: 0.45)); waitForRender(app)
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String)?.contains("faces=0,plates=1,documents=0,rectangles=0") == true)
    }

    @MainActor func testV43AutomaticEditsCannotEvictManualUndoHistory() {
        let app = launch(fixture: "two-people-car")
        // Analyze once before exercising Undo; cold Vision startup is covered separately.
        app.buttons["mode_faces"].tap(); waitForRender(app)
        app.buttons["mode_plate"].tap(); waitForRender(app)
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let automaticPixels = app.otherElements["processingComplete"].value as? String
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.35, dy: 0.3), to: CGVector(dx: 0.55, dy: 0.45)); waitForRender(app)
        XCTAssertTrue(app.buttons["blur_region_0"].waitForExistence(timeout: 5), "The test must actually create a Manual edit")
        XCTAssertTrue(app.buttons["Undo"].isEnabled)
        // The production ScopedUndoHistory policy is exercised beyond its capacity for
        // all four automatic categories in core tests. Keep representative native taps here.
        for _ in 0..<2 {
            app.buttons["mode_faces"].tap(); app.buttons["blurAllFaces"].tap()
            app.buttons["mode_plate"].tap(); app.buttons["blurAllPlates"].tap()
        }
        app.buttons["mode_faces"].tap(); app.buttons["mode_plate"].tap()
        app.buttons["mode_manual"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["Undo"].isEnabled)
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, automaticPixels,
            "Manual Undo must restore the exact automatic-layer pixels")
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String)?.contains("faces=2,plates=1,documents=0,rectangles=0") == true)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=1,plates=1,documents=0")
    }

    @MainActor func testV43FullCompositionAndScopedClears() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "combined-privacy", "-veil-cached-mask-fixture", "-veil-test-storage-id", UUID().uuidString, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        for tool in ["background", "faces", "plate", "documents"] {
            app.buttons["mode_\(tool)"].tap(); waitForRender(app, timeout: 120)
            if tool == "documents" { app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app) }
            if tool == "plate" { attach(app, "v43-background-faces-plates") }
        }
        app.buttons["mode_manual"].tap(); waitForRender(app)
        app.buttons["effectMenu"].tap(); app.buttons["Pixelate"].tap(); waitForRender(app)
        drag(app.scrollViews["photoCanvas"], from: CGVector(dx: 0.35, dy: 0.3), to: CGVector(dx: 0.55, dy: 0.45)); waitForRender(app)
        let populated = app.otherElements["privacySelectionCounts"].value as? String
        XCTAssertTrue(populated?.contains("background=1,faces=2,plates=1") == true)
        XCTAssertTrue(populated?.contains("rectangles=1") == true)
        XCTAssertFalse(populated?.contains("documents=0") == true)
        attach(app, "v43-full-five-layers")
        let fingerprint = app.otherElements["processingComplete"].value as? String
        app.buttons["finalPreview"].tap(); attach(app, "v43-full-done")
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, fingerprint)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        let savedExport = app.otherElements["exportFingerprint"].value as? String
        XCTAssertFalse(savedExport?.isEmpty ?? true)
        export(app, "v43-full-composition-share")
        app.buttons["Close"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["exportFingerprint"].value as? String, savedExport, "Save to Veil and Share must render the same full-resolution composition")
        app.buttons["finalPreview"].tap()
        for tool in ["background", "faces", "plate", "documents", "manual"] {
            app.buttons["mode_\(tool)"].tap(); waitForRender(app)
            let before = app.otherElements["privacySelectionCounts"].value as? String
            if tool == "documents" { app.buttons["documentCoverage"].tap() }
            if tool == "manual" { app.buttons["shapeMenu"].tap() }
            let clear = tool == "faces" ? "blurAllFaces" : tool == "plate" ? "blurAllPlates" : "clearAll"
            app.buttons[clear].tap(); waitForRender(app)
            let after = app.otherElements["privacySelectionCounts"].value as? String
            let key = tool == "plate" ? "plates" : tool == "manual" ? "rectangles" : tool
            let old = (before ?? "").split(separator: ","), new = (after ?? "").split(separator: ",")
            for (lhs, rhs) in zip(old, new) where !lhs.hasPrefix(key + "=") && !(tool == "manual" && lhs.hasPrefix("strokes=")) {
                XCTAssertEqual(lhs, rhs, "Clear All changed another layer")
            }
            XCTAssertTrue(after?.contains("\(key)=0") == true)
        }
    }

    @MainActor func testV41RenderedControlsAndGallery() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-reset-history", "-veil-test-storage-id", UUID().uuidString, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        attach(app, "v41-photo-loaded")
        for tool in ["background", "faces", "plate", "documents", "manual"] {
            app.buttons["mode_\(tool)"].tap(); waitForRender(app, timeout: 120)
            attach(app, "v41-tool-\(tool)")
        }
        for style in ["Pixelate", "Redact", "Blur"] {
            app.buttons["effectMenu"].tap(); app.buttons[style].tap(); waitForRender(app)
            attach(app, "v41-effect-\(style.lowercased())")
        }
        app.buttons["shapeMenu"].tap(); app.buttons["Ellipse"].tap()
        attach(app, "v41-manual-shape")
        let analysisBefore = app.otherElements["analysisCounts"].value as? String
        XCTAssertEqual(analysisBefore, "background=1,faces=1,plates=1,documents=1")
        let baseline = ["background", "faces", "plate", "documents", "manual"].map { app.buttons["mode_\($0)"].frame }
        for round in 0..<8 {
            for tool in ["faces", "plate", "documents", "manual", "background", "manual"] {
                app.buttons["mode_\(tool)"].tap()
                for (index, name) in ["background", "faces", "plate", "documents", "manual"].enumerated() {
                    let frame = app.buttons["mode_\(name)"].frame
                    XCTAssertEqual(frame.minX, baseline[index].minX, accuracy: 1)
                    XCTAssertEqual(frame.width, baseline[index].width, accuracy: 1)
                    XCTAssertEqual(frame.minY, baseline[index].minY, accuracy: 1)
                }
                if tool != "background" { XCTAssertTrue(app.buttons["mode_\(tool)"].isSelected) }
            }
            for style in ["Pixelate", "Redact", "Blur"] {
                app.buttons["effectMenu"].tap(); app.buttons[style].tap()
            }
            waitForRender(app, timeout: 120)
            for (index, tool) in ["background", "faces", "plate", "documents", "manual"].enumerated() {
                let frame = app.buttons["mode_\(tool)"].frame
                XCTAssertEqual(frame.minX, baseline[index].minX, accuracy: 1)
                XCTAssertEqual(frame.width, baseline[index].width, accuracy: 1)
                XCTAssertEqual(frame.minY, baseline[index].minY, accuracy: 1)
            }
            XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, analysisBefore)
            XCTAssertTrue(app.buttons["mode_manual"].isSelected)
            XCTAssertLessThanOrEqual(app.buttons["effectMenu"].frame.maxX, app.buttons["strength_low"].frame.minX)
            XCTAssertLessThanOrEqual(app.buttons["strength_low"].frame.maxX, app.buttons["strength_medium"].frame.minX)
            XCTAssertLessThanOrEqual(app.buttons["strength_medium"].frame.maxX, app.buttons["strength_strong"].frame.minX)
            if round == 0 || round == 7 { attach(app, "v41-stress-\(round)") }
        }
        app.buttons["finalPreview"].tap()
        for _ in 0..<2 {
            app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
            XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        }
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        attach(app, "v41-gallery-normal")
        app.buttons["Select"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        let photos = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_"))
        XCTAssertEqual(photos.count, 2)
        photos.element(boundBy: 0).tap(); photos.element(boundBy: 1).tap()
        attach(app, "v41-gallery-selection")
        XCTAssertTrue(app.buttons["galleryDeleteSelected"].isEnabled)
        XCTAssertGreaterThan(app.buttons["galleryDeleteSelected"].frame.midY, app.frame.height * 0.75)
        XCTAssertLessThan(app.buttons["gallerySelect"].frame.midY, app.frame.height * 0.25)
        XCTAssertEqual(app.staticTexts["gallerySelectionStatus"].label, "2 selected")
        app.buttons["galleryDeleteSelected"].tap(); app.buttons["Delete photos"].tap()
        XCTAssertTrue(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."].waitForExistence(timeout: 10))
    }

    @MainActor func testRapidEffectParametersKeepControlFrames() {
        let app = launch(fixture: "two-people-car")
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let tools = ["background", "faces", "plate", "documents", "manual"]
        let baseline = tools.map { app.buttons["mode_\($0)"].frame }
        let effectFrame = app.buttons["effectMenu"].frame
        for round in 0..<5 {
            for style in ["Pixelate", "Redact", "Blur"] {
                app.buttons["effectMenu"].tap(); app.buttons[style].tap()
                if style == "Redact" {
                    for color in ["White", "Black"] {
                        app.buttons["effectParameterMenu"].tap(); app.buttons[color].tap()
                    }
                } else {
                    app.buttons["strength_low"].tap(); app.buttons["strength_strong"].tap()
                }
                XCTAssertEqual(app.buttons["effectMenu"].frame.width, effectFrame.width, accuracy: 1)
                XCTAssertEqual(app.buttons["effectMenu"].frame.minY, effectFrame.minY, accuracy: 1)
            }
            for tool in ["faces", "documents", "manual"] { app.buttons["mode_\(tool)"].tap() }
            waitForRender(app, timeout: 120)
            for (index, tool) in tools.enumerated() {
                let frame = app.buttons["mode_\(tool)"].frame
                XCTAssertEqual(frame.minX, baseline[index].minX, accuracy: 1)
                XCTAssertEqual(frame.width, baseline[index].width, accuracy: 1)
                XCTAssertEqual(frame.minY, baseline[index].minY, accuracy: 1)
            }
            XCTAssertTrue(app.buttons["mode_manual"].isSelected)
            XCTAssertTrue(app.buttons["strength_strong"].isSelected)
        }
        attach(app, "v41-parameter-stress-final")
    }

    @MainActor func testGallerySelectionWithLargestText() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-reset-history",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); waitForRender(app)
        app.buttons["finalPreview"].tap(); app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        attach(app, "v41-largest-gallery-normal")
        app.buttons["gallerySelect"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        XCTAssertEqual(app.staticTexts["gallerySelectionStatus"].label, "1 selected")
        XCTAssertTrue(app.buttons["galleryDeleteSelected"].isEnabled)
        XCTAssertGreaterThan(app.buttons["galleryDeleteSelected"].frame.midY, app.frame.height * 0.75)
        attach(app, "v41-largest-gallery-selection")
        // Native toolbar AX bounds describe the visible control. Verify activation at the
        // edge of a 44-point target instead of mistaking symbol bounds for hit-test bounds.
        let trash = app.buttons["galleryDeleteSelected"].frame
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: trash.midX + 21, dy: trash.midY)).tap()
        XCTAssertTrue(app.buttons["Delete photos"].waitForExistence(timeout: 5))
        attach(app, "gallery-largest-delete-confirmation")
        app.buttons["Delete photos"].tap()
        XCTAssertTrue(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."].waitForExistence(timeout: 10))
    }

    @MainActor func testRapidRenderedStateChangesWithoutIdleBetweenSelections() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-mode", "manual", "-veil-rapid-selection-stress"]
        app.launch(); waitForRender(app)
        let tools = ["background", "faces", "plate", "documents", "manual"]
        let before = tools.map { app.buttons["mode_\($0)"].frame }
        let camera = transform(app)
        attach(app, "v41-rapid-state-initial")
        let completed = expectation(for: NSPredicate(format: "value == %@", "Complete"), evaluatedWith: app.otherElements["rapidSelectionStress"])
        wait(for: [completed], timeout: 120); waitForRender(app, timeout: 120)
        for (index, tool) in tools.enumerated() {
            let frame = app.buttons["mode_\(tool)"].frame
            XCTAssertEqual(frame.minX, before[index].minX, accuracy: 1)
            XCTAssertEqual(frame.width, before[index].width, accuracy: 1)
            XCTAssertEqual(frame.minY, before[index].minY, accuracy: 1)
        }
        XCTAssertTrue(app.buttons["mode_manual"].isSelected)
        XCTAssertTrue(app.buttons["strength_medium"].isSelected)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=1,faces=1,plates=1,documents=1")
        assertCamera(app, camera)
        XCTAssertLessThanOrEqual(app.buttons["effectMenu"].frame.maxX, app.buttons["strength_low"].frame.minX)
        attach(app, "v41-rapid-state-final")
    }

    @MainActor func testFirstLaunchSettingsAndPrivacy() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        attach(app, "first-launch")
        let guide = app.buttons["quickGuide"]
        if !guide.isHittable { app.swipeUp() }
        guide.tap()
        XCTAssertTrue(app.staticTexts["Cover the details"].waitForExistence(timeout: 5))
        attach(app, "quick-guide")
        app.buttons["Done"].tap()
        app.buttons["settings"].tap()
        XCTAssertTrue(app.buttons["About Veil"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Version / Build"].exists)
        attach(app, "settings")
        app.buttons["About Veil"].tap()
        XCTAssertTrue(app.staticTexts["Your photo. Your boundaries."].waitForExistence(timeout: 5))
        attach(app, "about")
        app.buttons["BackButton"].tap()
        app.buttons["photoPrivacy"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Photo processing happens on this iPhone.")).firstMatch.waitForExistence(timeout: 5))
        attach(app, "privacy")
        app.buttons["BackButton"].tap()
        let help = app.buttons["Help / Support"]
        if !help.isHittable { app.swipeUp() }
        help.tap()
        XCTAssertTrue(app.staticTexts["Before you share"].waitForExistence(timeout: 5))
        let metadata = app.buttons["Does Veil remove photo metadata?"]
        if !metadata.isHittable { app.swipeUp() }
        metadata.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Choose Remove metadata or Keep metadata in the Metadata tool")).firstMatch.waitForExistence(timeout: 5))
        attach(app, "metadata-help")
        metadata.tap()
        let download = app.buttons["A photo is taking time to open"]
        if !download.isHittable { app.swipeUp() }
        download.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "The system picker may need to download")).firstMatch.waitForExistence(timeout: 5))
        attach(app, "help-expanded")
    }

    @MainActor func testLargestTextToolAndStrengthMenus() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-mode", "plate", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        waitForRender(app)
        XCTAssertTrue(app.buttons["toolMenu"].waitForExistence(timeout: 10))
        attach(app, "largest-text-plates")
        app.buttons["Blur strength"].tap()
        app.buttons["Strong"].tap()
        waitForRender(app)
        XCTAssertEqual(app.buttons["Blur strength"].value as? String, "Strong")
        app.buttons["toolMenu"].tap()
        app.buttons["mode_manual"].tap()
        waitForRender(app)
        XCTAssertEqual(app.buttons["toolMenu"].value as? String, "Manual")
        XCTAssertTrue(app.buttons["manualBrush"].exists)
        attach(app, "largest-text-manual")
        for style in ["Pixelate", "Redact", "Blur"] {
            app.buttons["effectMenu"].tap(); app.buttons[style].tap(); waitForRender(app)
            attach(app, "v41-largest-text-\(style.lowercased())")
            let parameter = app.buttons["effectParameterMenu"]
            XCTAssertLessThanOrEqual(app.buttons["effectMenu"].frame.maxY, parameter.frame.minY)
            XCTAssertLessThanOrEqual(parameter.frame.maxY, app.buttons["shapeMenu"].frame.minY)
        }
        app.buttons["finalPreview"].tap()
        let change = app.buttons["metadataReviewChange"]
        XCTAssertTrue(change.waitForExistence(timeout: 5))
        XCTAssertEqual(change.value as? String, "Keep metadata")
        XCTAssertFalse(app.buttons["pillar_metadata"].exists)
        change.tap()
        XCTAssertTrue(app.buttons["metadataKeep"].isHittable)
        XCTAssertTrue(app.buttons["metadataRemove"].isHittable)
        XCTAssertLessThanOrEqual(app.buttons["metadataKeep"].frame.maxY, app.buttons["metadataRemove"].frame.minY)
        XCTAssertLessThanOrEqual(app.buttons["metadataRemove"].frame.maxY, app.buttons["pillar_metadata"].frame.minY)
        attach(app, "design-metadata-largest-keep")
        let remove = app.buttons["metadataRemove"]
        remove.tap(); XCTAssertTrue(remove.isSelected)
        attach(app, "design-metadata-largest-remove")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(change.value as? String, "Remove metadata")
        change.tap(); app.buttons["metadataKeep"].tap(); app.buttons["finalPreview"].tap()
        XCTAssertEqual(change.value as? String, "Keep metadata")
        XCTAssertFalse(app.buttons["metadataKeep"].exists, "Review summarizes choices instead of repeating editing controls")
        XCTAssertTrue(app.buttons["saveMenu"].exists)
        XCTAssertTrue(app.buttons["saveMenu"].isHittable, "Final review actions should be visible without scrolling")
        XCTAssertTrue(app.buttons["export"].isHittable)
        attach(app, "largest-text-metadata-choice")
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
        XCTAssertEqual(face.label, "Face 1")
        app.buttons["blurAllFaces"].tap(); waitForRender(app)
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

    @MainActor func testV42CachedAutomaticSelectionLifecycle() {
        for (tool, fixture, clear) in [("faces", "two-faces", "blurAllFaces"), ("plate", "two-people-car", "blurAllPlates"), ("documents", "sample-card", "clearAll")] {
            let app = launch(fixture: fixture)
            app.buttons["mode_\(tool)"].tap(); waitForRender(app)
            let originalSelection = app.otherElements["privacySelectionCounts"].value as? String
            let active = app.otherElements["processingComplete"].value as? String
            let analyses = app.otherElements["analysisCounts"].value as? String
            attach(app, "v42-\(tool)-active")
            if tool == "documents" { app.buttons["documentCoverage"].tap() }
            app.buttons[clear].tap(); waitForRender(app)
            XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, active)
            attach(app, "v42-\(tool)-cleared")
            app.buttons["mode_manual"].tap(); waitForRender(app)
            app.buttons["mode_\(tool)"].tap(); waitForRender(app)
            XCTAssertEqual(app.otherElements["privacySelectionCounts"].value as? String, originalSelection)
            XCTAssertEqual(app.otherElements["processingComplete"].value as? String, active)
            XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, analyses)
            attach(app, "v42-\(tool)-reactivated")
            app.terminate()
        }
    }

    @MainActor func testV42BackgroundClearCachedMaskAndUndo() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-veil-mode", "background", "-veil-cached-mask-fixture"]
        app.launch(); waitForRender(app)
        let active = app.otherElements["processingComplete"].value as? String
        attach(app, "v42-background-clear-control")
        app.buttons["clearAll"].tap(); waitForRender(app)
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, active)
        XCTAssertTrue(app.buttons["mode_background"].isSelected)
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, active)
        app.buttons["clearAll"].tap(); waitForRender(app)
        app.buttons["mode_manual"].tap(); app.buttons["mode_background"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, active)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=0,plates=0,documents=0")
        export(app, "v42-background-cached-export")
    }

    @MainActor func testV42ManualClearAllShapesAndUndo() {
        let app = launch(fixture: "two-people-car")
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let canvas = app.scrollViews["photoCanvas"]
        let empty = app.otherElements["processingComplete"].value as? String
        drag(canvas, from: CGVector(dx: 0.2, dy: 0.3), to: CGVector(dx: 0.4, dy: 0.5)); waitForRender(app)
        app.buttons["shapeMenu"].tap(); app.buttons["Ellipse"].tap()
        drag(canvas, from: CGVector(dx: 0.5, dy: 0.4), to: CGVector(dx: 0.7, dy: 0.6)); waitForRender(app)
        app.buttons["manualBrush"].tap()
        drag(canvas, from: CGVector(dx: 0.3, dy: 0.65), to: CGVector(dx: 0.65, dy: 0.65)); waitForRender(app)
        let populated = app.otherElements["privacySelectionCounts"].value as? String
        XCTAssertTrue(populated?.contains("rectangles=2,strokes=1") == true)
        app.buttons["shapeMenu"].tap(); attach(app, "v42-manual-clear-menu")
        app.buttons["clearAll"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, empty)
        XCTAssertTrue((app.otherElements["privacySelectionCounts"].value as? String)?.contains("rectangles=0,strokes=0") == true)
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["privacySelectionCounts"].value as? String, populated)
    }

    @MainActor func testV42PendingDetectionSurvivesToolReentry() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "empty-scene", "-veil-delay-faces"]
        app.launch(); waitForRender(app)
        app.buttons["mode_faces"].tap()
        app.buttons["mode_manual"].tap()
        // Other requested layers keep analyzing; changing focus cannot allow incomplete export.
        XCTAssertFalse(app.buttons["finalPreview"].isEnabled)
        app.buttons["mode_faces"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["detectionInProgress"].exists)
        XCTAssertFalse(app.buttons["finalPreview"].isEnabled)
        XCTAssertFalse(app.staticTexts["detectionFeedback"].exists)
        XCTAssertFalse(app.otherElements["processingComplete"].exists)
        XCTAssertTrue(app.staticTexts["detectionFeedback"].waitForExistence(timeout: 30))
        XCTAssertEqual(app.staticTexts["detectionFeedback"].label, "No faces detected. Try Manual.")
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=1,plates=0,documents=0")
    }

    @MainActor func testV42EmptyDetectionFeedback() {
        let app = launch(fixture: "empty-scene")
        for (tool, message) in [("faces", "No faces detected. Try Manual."), ("plate", "No plates detected. Try Manual."), ("documents", "No documents detected. Try Manual.")] {
            app.buttons["mode_\(tool)"].tap()
            XCTAssertTrue(app.staticTexts["detectionFeedback"].waitForExistence(timeout: 30))
            XCTAssertEqual(app.staticTexts["detectionFeedback"].label, message)
            attach(app, "v42-empty-\(tool)")
            let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.staticTexts["detectionFeedback"])
            wait(for: [gone], timeout: 15)
        }
        app.buttons["mode_background"].tap(); waitForRender(app)
        if app.buttons["mode_manual"].isSelected {
            XCTAssertEqual(app.staticTexts["detectionFeedback"].label, "Background unavailable. Try Manual.")
            attach(app, "v42-background-unavailable")
        }
    }

    @MainActor func testV42LandingAnimationOrReduceMotion() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-empty"]
        app.launch()
        let hero = app.otherElements["privacyDemonstration"]
        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Veil"].exists)
        if hero.value as? String == "Privacy tools preview" {
            attach(app, "v42-landing-reduce-motion")
            hero.tap()
            XCTAssertEqual(hero.value as? String, "Privacy tools preview")
        } else {
            for state in ["Visual privacy", "Original preview"] {
                let phase = expectation(for: NSPredicate(format: "value == %@", state), evaluatedWith: hero)
                wait(for: [phase], timeout: 15)
            }
            attach(app, "v42-landing-repeated-animation")
            hero.tap() // Take user control before observing the stable phase.
            let beforeTap = hero.value as? String
            hero.tap()
            let states = ["Original preview", "Visual privacy"]
            let index = states.firstIndex(of: beforeTap ?? "") ?? 0
            XCTAssertEqual(hero.value as? String, states[(index + 1) % states.count])
            attach(app, "v42-landing-interactive")
        }
    }

    @MainActor func testV42LandingLargerText() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.otherElements["privacyDemonstration"].waitForExistence(timeout: 10))
        attach(app, "v42-landing-largest-top")
        app.swipeUp()
        XCTAssertTrue(app.buttons["choosePhoto"].isHittable)
        attach(app, "v42-landing-largest-action")
        let guide = app.buttons["quickGuide"]
        if !guide.isHittable { app.swipeUp() }
        guide.tap()
        XCTAssertTrue(app.navigationBars["Welcome to Veil"].waitForExistence(timeout: 5))
        let review = app.staticTexts["Review, then share"]
        for _ in 0..<6 {
            if review.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(review.isHittable)
        attach(app, "quick-guide-largest")
        app.buttons["Done"].tap()
        app.buttons["settings"].tap()
        let help = app.buttons["Help / Support"]
        for _ in 0..<6 {
            if help.isHittable { break }
            app.swipeUp()
        }
        help.tap()
        XCTAssertTrue(app.staticTexts["Before you share"].waitForExistence(timeout: 5))
        let question = app.buttons["A photo is taking time to open"]
        for _ in 0..<6 {
            if question.isHittable { break }
            app.swipeUp()
        }
        question.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "The system picker may need to download")).firstMatch.waitForExistence(timeout: 5))
        attach(app, "help-largest-expanded")
    }

    @MainActor func testV42LandingAndGalleryConfirmationEvidence() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-empty"]
        app.launch(); XCTAssertTrue(app.buttons["choosePhoto"].waitForExistence(timeout: 10))
        attach(app, "v42-landing")
        for index in 0..<4 {
            app.otherElements["privacyDemonstration"].tap()
            attach(app, "design-hero-tap-\(index)")
        }
        app.terminate()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-faces", "-veil-mode", "faces", "-veil-reset-history"]
        app.launch(); waitForRender(app)
        app.buttons["finalPreview"].tap(); app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        attach(app, "v42-gallery-delete-action")
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.buttons["Delete photo"].waitForExistence(timeout: 5))
        attach(app, "v42-gallery-delete-confirmation")
        XCTAssertGreaterThan(app.buttons["Delete photo"].frame.midY, app.frame.height * 0.65)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["galleryShare"].exists)
        app.buttons["Delete"].tap(); app.buttons["Delete photo"].tap()
        XCTAssertTrue(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."].waitForExistence(timeout: 10))
        app.terminate()
        // This gallery-selection regression needs two outputs, using a fresh isolated legacy allowance.
        app.launchArguments += ["-veil-test-storage-id", UUID().uuidString, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        app.buttons["finalPreview"].tap()
        for _ in 0..<2 {
            app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
            XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        }
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap(); app.buttons["gallerySelect"].tap()
        let photos = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_"))
        XCTAssertTrue(photos.firstMatch.waitForExistence(timeout: 10)); XCTAssertEqual(photos.count, 2)
        photos.element(boundBy: 0).tap(); attach(app, "design-gallery-one-selected")
        photos.element(boundBy: 1).tap(); attach(app, "design-gallery-two-selected")
        app.buttons["galleryDeleteSelected"].tap()
        XCTAssertTrue(app.buttons["Delete photos"].waitForExistence(timeout: 5)); attach(app, "design-gallery-multiple-delete")
        app.buttons["galleryDeleteCancel"].tap(); XCTAssertEqual(app.staticTexts["gallerySelectionStatus"].label, "2 selected")
        app.buttons["galleryDeleteSelected"].tap(); app.buttons["Delete photos"].tap()
        XCTAssertTrue(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."].waitForExistence(timeout: 10))
    }

    @MainActor func testLocalGallerySaveRelaunchShareAndDelete() {
        let app = XCUIApplication()
        let scope = UUID().uuidString
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-faces", "-veil-mode", "faces", "-veil-reset-history", "-veil-test-storage-id", scope, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        app.buttons["pillar_metadata"].tap(); app.buttons["metadataRemove"].tap()
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Remove metadata")
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        app.terminate(); app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-test-storage-id", scope]; app.launch()
        app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); attach(app, "v4-gallery-local-reloaded")
        photo.tap(); attach(app, "v4-gallery-photo")
        XCTAssertTrue(app.staticTexts["galleryMetadataRemoval"].exists)
        // Inspect/cancel Share before consuming the final legacy export with Photos.
        app.buttons["galleryShare"].tap(); XCTAssertTrue(app.staticTexts["Copy"].waitForExistence(timeout: 10)); attach(app, "v4-gallery-share")
        XCTAssertTrue(app.buttons["Close"].exists); app.buttons["Close"].tap()
        app.buttons["gallerySaveToPhotos"].tap()
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if system.alerts.firstMatch.waitForExistence(timeout: 5) {
            let allow = system.alerts.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND NOT label CONTAINS %@", "Allow", "Don’t")).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.staticTexts["Saved to Photos · source metadata removed"].waitForExistence(timeout: 15))
        app.alerts.buttons["OK"].tap()
        app.terminate(); app.launch(); app.buttons["gallery"].tap(); photo.tap()
        app.buttons["Delete"].tap(); app.buttons["Delete photo"].tap()
        XCTAssertTrue(app.staticTexts["Your finished photos live here. Choose Save to Veil after editing."].waitForExistence(timeout: 10))
        attach(app, "v4-gallery-empty")
    }

    @MainActor func testPixelateEllipseUndoAndExport() {
        let app = launch(fixture: "two-people-car")
        let canvas = app.scrollViews["photoCanvas"]
        app.buttons["mode_manual"].tap(); waitForRender(app)
        let camera = transform(app)
        app.buttons["shapeMenu"].tap(); app.buttons["Ellipse"].tap()
        XCTAssertEqual(app.buttons["shapeMenu"].value as? String, "Ellipse")
        app.buttons["manualBrush"].tap()
        XCTAssertEqual(app.buttons["shapeMenu"].value as? String, "Brush")
        XCTAssertEqual(app.buttons["manualBrush"].label, "Ellipse selection")
        app.buttons["manualBrush"].tap()
        XCTAssertEqual(app.buttons["shapeMenu"].value as? String, "Ellipse")
        drag(canvas, from: CGVector(dx: 0.3, dy: 0.35), to: CGVector(dx: 0.65, dy: 0.6)); waitForRender(app)
        let gaussian = app.otherElements["processingComplete"].value as? String
        app.buttons["effectMenu"].tap(); app.buttons["Pixelate"].tap(); waitForRender(app)
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, gaussian)
        assertCamera(app, camera); attach(app, "v4-pixelate-ellipse")
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, gaussian)
        app.buttons["effectMenu"].tap(); app.buttons["Pixelate"].tap(); waitForRender(app)
        app.buttons["finalPreview"].tap(); export(app, "v4-pixelate-clean-share")
    }

    @MainActor func testDocumentDetailsAndWholeRedaction() {
        let app = launch(fixture: "sample-card")
        let before = transform(app)
        app.buttons["mode_documents"].tap()
        // A detected region is published only after real Vision analysis completes.
        // Hosted cold analysis was still pending after 55 s and completed before
        // the later ~105 s post-activation snapshot. Scope this cap to analysis, not rendering.
        guard app.buttons["document_0"].waitForExistence(timeout: 120) else {
            XCTFail("Document analysis did not publish a detected region")
            return
        }
        XCTAssertFalse(app.activityIndicators["detectionInProgress"].exists)
        waitForRender(app)
        XCTAssertTrue(app.buttons["document_0"].label.hasPrefix("Hidden document region"))
        XCTAssertFalse(app.staticTexts["detectionFeedback"].exists)
        let detailsBlur = app.otherElements["processingComplete"].value as? String
        attach(app, "v4-document-details")
        app.buttons["effectMenu"].tap(); app.buttons["Redact"].tap(); waitForRender(app)
        let detailsRedact = app.otherElements["processingComplete"].value as? String
        XCTAssertNotEqual(detailsRedact, detailsBlur, "Details redaction must change rendered pixels")
        app.buttons["documentCoverage"].tap(); app.buttons["Hide entire document"].tap(); waitForRender(app)
        let wholeRedact = app.otherElements["processingComplete"].value as? String
        XCTAssertNotEqual(wholeRedact, detailsRedact, "Whole-document coverage must change rendered pixels")
        assertCamera(app, before); attach(app, "v4-document-whole-redact")
        app.buttons["document_0"].tap(); waitForRender(app)
        XCTAssertNotEqual(app.otherElements["processingComplete"].value as? String, wholeRedact)
        app.buttons["document_0"].tap(); waitForRender(app)
        XCTAssertEqual(app.otherElements["processingComplete"].value as? String, wholeRedact)
        XCTAssertEqual(app.otherElements["analysisCounts"].value as? String, "background=0,faces=0,plates=0,documents=1")
        app.buttons["finalPreview"].tap(); export(app, "v4-document-clean-share")
    }

    @MainActor func testSmallFacesRemainIndependentOfZoom() {
        let app = launch(fixture: "faces-small-landscape")
        let canvas = app.scrollViews["photoCanvas"]
        canvas.pinch(withScale: 2, velocity: 1); let before = transform(app)
        app.buttons["mode_faces"].tap(); waitForRender(app, timeout: 120)
        XCTAssertTrue(app.buttons["face_0"].exists); XCTAssertTrue(app.buttons["face_1"].exists)
        assertCamera(app, before); attach(app, "v4-small-faces-zoom-preserved")
        app.buttons["fitPhoto"].tap(); attach(app, "v4-small-faces-fit")
    }

    @MainActor func testWatermarkCustomTextStylesAndExportPaths() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-faces", "-veil-mode", "faces", "-veil-reset-history", "-veil-synthetic-watermark-evidence", "-veil-test-storage-id", UUID().uuidString, "-veil-legacy-usage", "0"]
        app.launch(); waitForRender(app)
        let editingViewport = transform(app)
        app.buttons["pillar_watermark"].tap(); assertCamera(app, editingViewport)
        attach(app, "design-watermark-empty")
        app.buttons["pillar_metadata"].tap(); assertCamera(app, editingViewport)
        XCTAssertTrue(app.buttons["metadataKeep"].isSelected)
        attach(app, "design-metadata-keep")
        app.buttons["metadataRemove"].tap(); attach(app, "design-metadata-remove")
        app.buttons["finalPreview"].tap(); assertCamera(app, editingViewport)
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Remove metadata")
        XCTAssertFalse(app.buttons["pillar_metadata"].exists)
        attach(app, "design-final-review-remove")
        app.buttons["finalPreview"].tap()
        app.buttons["pillar_metadata"].tap(); app.buttons["metadataKeep"].tap()
        app.buttons["pillar_watermark"].tap(); app.buttons["watermarkAdd"].tap(); waitForRender(app)
        app.buttons["watermarkText"].tap()
        let field = app.descendants(matching: .any).matching(identifier: "watermarkTextField").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        app.buttons["watermarkClearText"].tap()
        field.typeText("For synthetic testing only")
        XCTAssertEqual(field.value as? String, "For synthetic testing only")
        app.buttons["watermarkApplyText"].tap(); waitForRender(app)
        app.buttons["watermarkStyle"].tap(); app.buttons["Stamp"].tap(); waitForRender(app)
        app.buttons["watermarkRepeat"].tap(); waitForRender(app)
        app.buttons["watermarkPlacement"].tap(); app.buttons["Bottom"].tap(); waitForRender(app)
        app.buttons["watermarkAdjust"].tap()
        XCTAssertTrue(app.sliders["watermarkSize"].waitForExistence(timeout: 5))
        app.sliders["watermarkSize"].adjust(toNormalizedSliderPosition: 0.45)
        app.sliders["watermarkOpacity"].adjust(toNormalizedSliderPosition: 0.65)
        app.sliders["watermarkRotation"].adjust(toNormalizedSliderPosition: 0.35)
        app.buttons["watermarkAdjustDone"].tap(); waitForRender(app)
        attach(app, "watermark-custom-composition")
        app.buttons["finalPreview"].tap()
        XCTAssertEqual(app.buttons["metadataReviewChange"].value as? String, "Keep metadata")
        XCTAssertFalse(app.buttons["metadataKeep"].exists)
        attach(app, "design-final-review-watermark-keep")
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); app.buttons["dismissSaveNotice"].tap()
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        XCTAssertTrue(app.staticTexts["Exports keep supported metadata"].exists)
        attach(app, "watermark-gallery-flattened")
        // Cancel Share before the second completed export uses the free allowance.
        app.buttons["galleryShare"].tap()
        XCTAssertTrue(app.staticTexts["Copy"].waitForExistence(timeout: 15)); attach(app, "watermark-gallery-share")
        app.buttons["Close"].tap()
        app.buttons["gallerySaveToPhotos"].tap()
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if system.alerts.firstMatch.waitForExistence(timeout: 5) {
            let allow = system.alerts.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND NOT label CONTAINS %@", "Allow", "Don’t")).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.staticTexts["Saved to Photos · supported metadata kept"].waitForExistence(timeout: 15)); app.alerts.buttons["OK"].tap()
    }

    @MainActor func testWatermarkControlsWithLargestText() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-people-car", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-veil-synthetic-watermark-evidence"]
        app.launch(); waitForRender(app)
        let before = transform(app)
        app.buttons["pillar_watermark"].tap(); app.buttons["watermarkAdd"].tap(); waitForRender(app)
        assertCamera(app, before)
        XCTAssertTrue(app.buttons["watermarkText"].isHittable)
        let textButton = app.buttons["watermarkText"], styleButton = app.buttons["watermarkStyle"]
        XCTAssertLessThanOrEqual(textButton.frame.maxY, styleButton.frame.minY + 1, "Accessible text controls stack without overlap")
        for control in [textButton, styleButton] {
            XCTAssertGreaterThanOrEqual(control.frame.minX, 0)
            XCTAssertLessThanOrEqual(control.frame.maxX, app.frame.width)
            XCTAssertLessThanOrEqual(control.frame.maxY, app.buttons["pillar_watermark"].frame.minY)
        }
        let remove = app.buttons["watermarkRemove"]
        if !remove.isHittable { app.swipeUp() }
        XCTAssertTrue(remove.isHittable)
        attach(app, "watermark-largest-controls")
        textButton.tap()
        XCTAssertTrue(app.buttons["watermarkClearText"].waitForExistence(timeout: 5))
        attach(app, "watermark-largest-text-editor")
        app.buttons["Cancel"].tap()
        remove.tap(); waitForRender(app)
        app.buttons["Undo"].tap(); waitForRender(app)
        XCTAssertTrue(app.buttons["watermarkText"].exists)
        app.buttons["pillar_metadata"].tap(); assertCamera(app, before)
        app.buttons["pillar_redact"].tap(); assertCamera(app, before)
    }

    @MainActor func testOptionalAccountUnconfigured() {
        let app = XCUIApplication(); app.launch()
        app.buttons["settings"].tap(); app.buttons["account"].tap()
        XCTAssertTrue(app.staticTexts["localGalleryAvailability"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["continueWithApple"].exists)
        XCTAssertFalse(app.buttons["continueWithGoogle"].exists)
        attach(app, "v41-account-local-only")
        if !app.buttons["Configuration details"].isHittable { app.swipeUp() }
        app.buttons["Configuration details"].tap()
        XCTAssertTrue(app.staticTexts["backendDiagnostic"].waitForExistence(timeout: 5))
    }

    @MainActor func testConfiguredProviderControlsPreview() {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-empty", "-veil-auth-controls-preview"]
        app.launch(); app.buttons["settings"].tap(); app.buttons["account"].tap()
        XCTAssertTrue(app.buttons["continueWithApple"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["continueWithGoogle"].exists)
        XCTAssertFalse(app.buttons["continueWithApple"].isEnabled)
        XCTAssertFalse(app.buttons["continueWithGoogle"].isEnabled)
        XCTAssertFalse(app.staticTexts["localGalleryAvailability"].exists)
        attach(app, "v41-account-provider-controls-preview")
    }

    @MainActor func testPhotosPickerWithoutReadAuthorization() {
        let app = XCUIApplication(); app.launch(); app.buttons["choosePhoto"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 10))
        XCTAssertFalse(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch.exists)
        attach(app, "v4-picker-selection-scoped"); app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["choosePhoto"].exists)
    }

    @MainActor func testSaveToPhotosAddOnly() {
        let app = launch(fixture: "two-faces")
        app.buttons["mode_faces"].tap(); waitForRender(app)
        app.buttons["finalPreview"].tap(); app.buttons["saveMenu"].tap(); app.buttons["saveToPhotos"].tap()
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if system.alerts.firstMatch.waitForExistence(timeout: 5) {
            attach(system, "v4-photos-add-only-permission")
            let allow = system.alerts.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND NOT label CONTAINS %@", "Allow", "Don’t")).firstMatch
            if allow.exists { allow.tap() }
        }
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 15)); attach(app, "v4-saved-to-photos")
        app.buttons["dismissSaveNotice"].tap(); XCTAssertTrue(app.buttons["export"].exists)
    }

    @MainActor private func checkBackground(fixture: String, name: String) {
        let app = launch(fixture: fixture)
        let before = transform(app)
        app.buttons["mode_background"].tap()
        // A cold hosted Simulator can take over 45s to initialize Vision before returning its fallback.
        // Keep the normal bound for interactive edits; only foreground model startup gets extra time.
        waitForRender(app, timeout: 120)
        let state = app.otherElements["processingComplete"].label
        if state == "Manual fallback" {
            XCTAssertEqual(app.staticTexts["detectionFeedback"].label, "Background unavailable. Try Manual.")
            assertCamera(app, before)
            attach(app, "background-\(name)-fallback")
            return // Simulator Vision may lack foreground model support; report explicitly.
        }
        assertCamera(app, before)
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
        let exportButton = app.buttons["export"]
        if !exportButton.waitForExistence(timeout: 2) { app.buttons["finalPreview"].tap() }
        XCTAssertTrue(exportButton.waitForExistence(timeout: 10))
        exportButton.tap()
        XCTAssertTrue(app.staticTexts["Copy"].waitForExistence(timeout: 15))
        attach(app, name)
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
