import XCTest
import StoreKit
import StoreKitTest

/// App-owned quota, persistence and paywall integration, with synthetic photo input.
final class VeilCommerceUITests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    @MainActor private func launch(scope: String, extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-veil-ui-testing", "-veil-fixture", "two-faces", "-veil-test-storage-id", scope] + extra
        app.launch()
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 30))
        return app
    }
    @MainActor private func save(_ app: XCUIApplication) {
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["dismissSaveNotice"].waitForExistence(timeout: 20))
        app.buttons["dismissSaveNotice"].tap()
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testTwoFreeExportsThenPaywallPersistsAcrossRestartAndGallery() {
        let scope = UUID().uuidString
        var app = launch(scope: scope, extra: ["-veil-legacy-usage", "0"])
        app.buttons["finalPreview"].tap()
        save(app); save(app)
        let previewMark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        XCTAssertTrue(previewMark.waitForExistence(timeout: 10))
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        if app.alerts.firstMatch.exists { app.alerts.buttons["OK"].tap() }
        XCTAssertFalse(app.staticTexts["subscriptionPrivacyUnavailable"].exists)
        attach(app, "commerce-third-export-dark")
        let privacy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Privacy Policy")).firstMatch
        XCTAssertTrue(privacy.waitForExistence(timeout: 5), "Published policy must be exposed as a named native action")
        XCTAssertTrue(privacy.isEnabled)

        app.buttons["subscriptionClose"].tap()
        XCTAssertTrue(app.buttons["export"].exists, "Dismissing paywall retains editor")
        app.terminate()
        app = launch(scope: scope)
        app.buttons["finalPreview"].tap()
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        if app.alerts.firstMatch.exists { app.alerts.buttons["OK"].tap() }
        app.buttons["subscriptionClose"].tap()
        app.buttons["Close photo"].tap()
        app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        XCTAssertTrue(previewMark.exists, "Gallery thumbnails remain protected")
        photo.tap()
        XCTAssertTrue(previewMark.exists, "Gallery detail remains protected")
        app.buttons["galleryShare"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        if app.alerts.firstMatch.exists { app.alerts.buttons["OK"].tap() }
        attach(app, "commerce-gallery-gated")
    }
    @MainActor func testNativeTrialUnlocksExportsAndSurvivesAppRestart() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "VeilLocal", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState(); session.clearTransactions()
        session.disableDialogs = true; session.timeRate = .realTime
        session.storefront = "POL"; session.locale = Locale(identifier: "pl_PL")
        defer { session.clearTransactions() }
        // Signed environment/bundle checks run in the app-hosted integration
        // helper. This runner has a separate bundle; exercise the actual UI
        // purchase here, rather than an unrelated prelaunch off-device purchase.
        XCTAssertTrue(session.allTransactions().isEmpty)
        let scope = UUID().uuidString
        var app = launch(scope: scope, extra: ["-veil-storekit-testing"])
        app.buttons["finalPreview"].tap(); save(app)
        let mark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10))
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        let yearly = app.buttons["subscriptionPlanYearly"]
        XCTAssertTrue(yearly.waitForExistence(timeout: 15))
        let purchase = app.buttons["subscriptionPurchase"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND label == %@", "Start 3-Day Free Trial"), object: purchase)
        await fulfillment(of: [ready], timeout: 15)
        app.buttons["subscriptionPlanMonthly"].tap()
        attach(app, "commerce-loaded-monthly-trial")
        yearly.tap()
        attach(app, "commerce-loaded-yearly-trial")
        purchase.tap()
        let status = app.buttons["subscriptionManage"]
        // A successful purchase changes the paywall to the subscription summary.
        XCTAssertTrue(status.waitForExistence(timeout: 15))
        let transactions = session.allTransactions()
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.productIdentifier, "vail.pro.annual")
        let trial = try XCTUnwrap(transactions.first)
        XCTAssertEqual(try XCTUnwrap(trial.expirationDate).timeIntervalSince(trial.purchaseDate), 3 * 24 * 60 * 60, accuracy: 1)
        app.buttons["subscriptionClose"].tap()
        XCTAssertFalse(mark.exists, "Verified Pro removes preview marks immediately")
        XCTAssertFalse(app.buttons["unlockCleanExports"].exists)
        save(app); save(app) // Further clean exports are now permitted.
        app.terminate()
        app = launch(scope: scope, extra: ["-veil-storekit-testing"])
        app.buttons["finalPreview"].tap(); save(app)
        XCTAssertFalse(app.buttons["subscriptionClose"].exists)
    }
    @MainActor func testCancelledEditorAndGallerySharesDoNotConsumeExports() {
        XCUIApplication().resetAuthorizationStatus(for: .photos)
        defer { XCUIApplication().resetAuthorizationStatus(for: .photos) }
        let app = launch(scope: UUID().uuidString, extra: ["-veil-legacy-usage", "0"])
        app.buttons["finalPreview"].tap()
        // Actual native denial must release the export lease and consume no allowance.
        app.buttons["saveMenu"].tap(); app.buttons["saveToPhotos"].tap()
        let system = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = system.alerts.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Don")).firstMatch
        XCTAssertTrue(deny.waitForExistence(timeout: 10)); deny.tap()
        XCTAssertTrue(app.staticTexts["Photos saving is disabled. You can allow it in iPhone Settings, or use Share or Save to Veil."].waitForExistence(timeout: 10))
        app.alerts.buttons["OK"].tap()
        app.buttons["export"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 15)); app.buttons["Close"].tap()
        save(app)
        app.buttons["Close photo"].tap(); app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        app.buttons["galleryShare"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 15)); app.buttons["Close"].tap()
        attach(app, "commerce-gallery-cancelled-share")
        // Both cancellations leave the second free operation available.
        app.terminate(); app.launch()
        XCTAssertTrue(app.otherElements["processingComplete"].waitForExistence(timeout: 30))
        app.buttons["finalPreview"].tap(); save(app)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
    }
    @MainActor func testCompletedShareConsumesOneExport() {
        let app = launch(scope: UUID().uuidString, extra: ["-veil-legacy-usage", "0"])
        app.buttons["finalPreview"].tap(); app.buttons["export"].tap()
        let copy = app.staticTexts["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 15)); copy.tap()
        let available = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["saveMenu"])
        XCTAssertEqual(XCTWaiter.wait(for: [available], timeout: 10), .completed)
        save(app)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
    }
    @MainActor func testNewUserOneExportBlocksEveryCleanDestinationAfterRestart() {
        let scope = UUID().uuidString
        var app = launch(scope: scope)
        app.buttons["Close photo"].tap()
        XCTAssertEqual(app.staticTexts["freeExportAllowance"].label, "Your first export is free")
        app.terminate(); app = launch(scope: scope)
        app.buttons["finalPreview"].tap()
        app.buttons["export"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 15)); app.buttons["Close"].tap()
        save(app)
        let mark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10))
        for destination in ["saveToVeil", "saveToPhotos"] {
            app.buttons["saveMenu"].tap(); app.buttons[destination].tap()
            XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
            app.buttons["subscriptionClose"].tap()
        }
        app.buttons["export"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        app.buttons["subscriptionClose"].tap()
        app.terminate(); app = launch(scope: scope)
        XCTAssertTrue(mark.waitForExistence(timeout: 10))
        app.buttons["Close photo"].tap()
        XCTAssertEqual(app.staticTexts["freeExportAllowance"].label, "Free export used")
        app.buttons["gallery"].tap()
        let photo = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery_")).firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 10)); photo.tap()
        for destination in ["galleryShare", "gallerySaveToPhotos"] {
            XCTAssertTrue(app.buttons[destination].exists)
            app.buttons[destination].tap()
            XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
            app.buttons["subscriptionClose"].tap()
        }
        attach(app, "vail11-new-user-exhausted")
    }
    @MainActor func testLegacyOneUsedPreservesRemainingShareAndThenBlocksSave() {
        let scope = UUID().uuidString
        var app = launch(scope: scope, extra: ["-veil-legacy-usage", "1"])
        app.buttons["Close photo"].tap()
        XCTAssertEqual(app.staticTexts["freeExportAllowance"].label, "1 free export remaining")
        app.terminate(); app = launch(scope: scope)
        app.buttons["finalPreview"].tap(); app.buttons["export"].tap()
        let copy = app.staticTexts["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 15)); copy.tap()
        let available = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["saveMenu"])
        XCTAssertEqual(XCTWaiter.wait(for: [available], timeout: 10), .completed)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        app.buttons["subscriptionClose"].tap()
        app.terminate(); app = launch(scope: scope)
        let mark = app.descendants(matching: .any).matching(identifier: "premiumPreviewWatermark").firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 10))
        attach(app, "vail11-legacy-share-exhausted")
    }
    @MainActor func testPaywallLargestTextAndLightAppearance() {
        let app = launch(scope: UUID().uuidString, extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.buttons["finalPreview"].tap(); save(app)
        app.buttons["saveMenu"].tap(); app.buttons["saveToVeil"].tap()
        XCTAssertTrue(app.buttons["subscriptionClose"].waitForExistence(timeout: 15))
        if app.alerts.firstMatch.exists { app.alerts.buttons["OK"].tap() }
        attach(app, "commerce-largest-top")
        // Scroll to the actual footer rather than assuming a fixed number of screens
        // at the largest accessibility size.
        let restore = app.buttons["subscriptionRestore"]
        for _ in 0..<10 {
            if restore.isHittable { break }
            app.swipeUp()
        }
        attach(app, "commerce-largest-bottom")
        XCTAssertTrue(restore.isHittable)
        XCTAssertTrue(app.buttons["subscriptionClose"].isHittable)
    }
}
