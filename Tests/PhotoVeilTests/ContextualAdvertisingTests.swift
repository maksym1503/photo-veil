import Foundation
import XCTest
@testable import ImageGeometry

final class ContextualAdvertisingTests: XCTestCase {
    private let inventory = URL(string: "https://ads.veil.com/v1/contextual")!
    private let privacy = URL(string: "https://ads.veil.com/privacy")!
    private let report = URL(string: "https://ads.veil.com/report")!

    private func configuration(appPrivacyPublished: Bool = true, supportPublished: Bool = true) -> ContextualAdvertisingConfiguration? {
        ContextualAdvertisingConfiguration(inventoryURL: inventory, providerPrivacyURL: privacy,
            reportURL: report, providerDisplayName: "Veil Contextual Ads",
            disclosureVersion: "2026-10-v1", appPrivacyPublished: appPrivacyPublished,
            supportPublished: supportPublished)
    }

    private func creative() -> ContextualAdvertisingCreative? {
        let json = """
        {"advertiser":"Sample Advertiser","headline":"A contextual offer","callToAction":"Learn more","destinationURL":"https://shop.veil.com/item","reportURL":"https://ads.veil.com/report"}
        """
        return ContextualAdvertisingCreative.decode(Data(json.utf8), configuration: configuration()!)
    }

    @MainActor private func allow(_ controller: ContextualAdvertisingController) {
        controller.setConsent(.granted(disclosureVersion: "2026-10-v1"))
        controller.setEntitlement(.verifiedFree)
        controller.setHomeVisible(true)
        controller.setSceneActive(true)
    }

    func testConfigurationRequiresPublishedReadinessAndRealHTTPSURLs() {
        XCTAssertNotNil(configuration())
        XCTAssertNil(configuration(appPrivacyPublished: false))
        XCTAssertNil(configuration(supportPublished: false))

        for text in ["http://ads.veil.com/inventory", "https://user@ads.veil.com/inventory",
                     "https://ads.veil.com/inventory?device=1", "https://localhost/inventory",
                     "https://ads.example.com/inventory", "https://ads.veil.example.net/inventory#fragment",
                     "https://127.0.0.1/inventory", "https://[::1]/inventory",
                     "https://0177.0.0.1/inventory", "https://0x7f000001/inventory",
                     "https://ads.veil.com:8443/inventory", "https://service.localhost/inventory",
                     "https://ads.example.com./inventory", "https://printer.home.arpa/inventory"] {
            let invalid = ContextualAdvertisingConfiguration(inventoryURL: URL(string: text)!,
                providerPrivacyURL: privacy, reportURL: report, providerDisplayName: "Provider",
                disclosureVersion: ContextualAdvertisingConfiguration.supportedDisclosureVersion,
                appPrivacyPublished: true, supportPublished: true)
            XCTAssertNil(invalid, "Accepted unsupported inventory URL: \(text)")
        }
        XCTAssertNil(ContextualAdvertisingConfiguration(inventoryURL: inventory,
            providerPrivacyURL: URL(string: "https://127.0.0.1/privacy")!, reportURL: report,
            providerDisplayName: "Provider", disclosureVersion: ContextualAdvertisingConfiguration.supportedDisclosureVersion,
            appPrivacyPublished: true, supportPublished: true))
        XCTAssertNil(ContextualAdvertisingConfiguration(inventoryURL: inventory, providerPrivacyURL: privacy,
            reportURL: URL(string: "https://ads.veil.com:9443/report")!, providerDisplayName: "Provider",
            disclosureVersion: ContextualAdvertisingConfiguration.supportedDisclosureVersion,
            appPrivacyPublished: true, supportPublished: true))
        XCTAssertNil(ContextualAdvertisingConfiguration(inventoryURL: inventory, providerPrivacyURL: privacy,
            reportURL: report, providerDisplayName: "Provider", disclosureVersion: "v1",
            appPrivacyPublished: true, supportPublished: false))
        XCTAssertNil(ContextualAdvertisingConfiguration(inventoryURL: inventory, providerPrivacyURL: privacy,
            reportURL: report, providerDisplayName: "Provider", disclosureVersion: "v2",
            appPrivacyPublished: true, supportPublished: true))
        XCTAssertTrue(ContextualAdvertisingConfiguration.dataDisclosureText.contains("IP address"))
        for excluded in ["photos", "photo metadata", "OCR text", "account details", "editing activity"] {
            XCTAssertTrue(ContextualAdvertisingConfiguration.dataDisclosureText.contains(excluded))
        }
    }

    @MainActor func testUnknownConsentAndEveryNonFreeEntitlementSuppressRequests() async {
        let config = configuration()!
        let provider = TestProvider(result: creative())
        let controller = ContextualAdvertisingController(configuration: config, provider: provider)
        XCTAssertEqual(controller.consent, .unknown)
        XCTAssertEqual(controller.entitlement, .unknown)
        controller.setConsent(.granted(disclosureVersion: config.disclosureVersion))
        controller.setEntitlement(.verifiedFree)
        XCTAssertEqual(provider.calls, 0, "Hidden home view must not request inventory")
        controller.setHomeVisible(true)
        XCTAssertEqual(provider.calls, 0, "Inactive scene must not request inventory")
        controller.setSceneActive(true)
        await provider.waitUntilStarted()
        await controller.requestTask?.value
        XCTAssertNotNil(controller.creative)
        for entitlement in [ContextualAdvertisingEntitlement.unknown, .checking, .loading, .busy, .pro, .unavailable] {
            controller.setEntitlement(entitlement)
            XCTAssertNil(controller.creative)
            XCTAssertNil(controller.requestTask, "Ineligible state must not even schedule a request")
        }
        XCTAssertEqual(provider.calls, 1)
        controller.setEntitlement(.verifiedFree)
        await provider.waitUntilStarted(callNumber: 2)
        await controller.requestTask?.value
        XCTAssertEqual(controller.creative, creative())
    }

    @MainActor func testConsentMustMatchCurrentDisclosureVersion() async {
        let provider = TestProvider(result: creative())
        let controller = ContextualAdvertisingController(configuration: configuration(), provider: provider)
        controller.setEntitlement(.verifiedFree)
        controller.setHomeVisible(true)
        controller.setSceneActive(true)
        controller.setConsent(.granted(disclosureVersion: "old-version"))
        XCTAssertNil(controller.creative)
        XCTAssertEqual(provider.calls, 0)
        XCTAssertNil(controller.requestTask)
        controller.setConsent(.granted(disclosureVersion: "2026-10-v1"))
        await provider.waitUntilStarted()
        await controller.requestTask?.value
        XCTAssertNotNil(controller.creative)
    }

    @MainActor func testNoProviderNoFillAndProviderFailureStayQuiet() async {
        let disabled = ContextualAdvertisingController(configuration: configuration())
        allow(disabled)
        XCTAssertNil(disabled.creative)

        let readinessProvider = TestProvider(result: creative())
        let unready = ContextualAdvertisingController(configuration: configuration(appPrivacyPublished: false), provider: readinessProvider)
        allow(unready)
        XCTAssertEqual(readinessProvider.calls, 0)

        let noFillProvider = TestProvider(result: nil)
        let noFill = ContextualAdvertisingController(configuration: configuration(), provider: noFillProvider)
        allow(noFill)
        await noFillProvider.waitUntilStarted()
        await noFill.requestTask?.value
        XCTAssertNil(noFill.creative)

        let failingProvider = TestProvider(error: TestProvider.TestFailure.failed)
        let failing = ContextualAdvertisingController(configuration: configuration(), provider: failingProvider)
        allow(failing)
        await failingProvider.waitUntilStarted()
        await failing.requestTask?.value
        XCTAssertNil(failing.creative)
    }

    @MainActor func testStaleResponseIsDiscardedAfterProNavigationOrBackground() async {
        for invalidation: (ContextualAdvertisingController) -> Void in [
            { $0.setEntitlement(.pro) },
            { $0.setHomeVisible(false) },
            { $0.setSceneActive(false) },
            { $0.setConsent(.unknown) },
            { $0.setConfiguration(nil, provider: nil) }
        ] {
            let provider = TestProvider(pends: true)
            let controller = ContextualAdvertisingController(configuration: configuration(), provider: provider)
            allow(controller)
            await provider.waitUntilStarted()
            let inFlightRequest = controller.requestTask
            invalidation(controller)
            XCTAssertNil(controller.creative)
            provider.completeFirst(creative())
            await inFlightRequest?.value
            XCTAssertNil(controller.creative)
        }
    }

    func testDecoderEnforcesByteTextAndURIBoundsAndExactSchema() {
        let config = configuration()!
        let valid = """
        {"advertiser":"A","headline":"H","callToAction":"Go","destinationURL":"https://shop.veil.com/path","reportURL":"https://ads.veil.com/report"}
        """
        XCTAssertNotNil(ContextualAdvertisingCreative.decode(Data(valid.utf8), configuration: config))
        XCTAssertEqual(ContextualAdvertisingCreative.decode(Data(valid.utf8), configuration: config)?.privacyURL, config.providerPrivacyURL)
        XCTAssertNil(ContextualAdvertisingCreative.decode(Data(repeating: 32, count: ContextualAdvertisingLimits.maximumResponseBytes + 1), configuration: config))
        for mutation in [
            valid.replacingOccurrences(of: "\"A\"", with: "\"\\nInjected\""),
            valid.replacingOccurrences(of: "https://shop.veil.com/path", with: "http://shop.veil.com/path"),
            valid.replacingOccurrences(of: "https://shop.veil.com/path", with: "https://user@shop.veil.com/path"),
            valid.replacingOccurrences(of: "https://shop.veil.com/path", with: "https://shop.veil.com/path?campaign=1"),
            valid.replacingOccurrences(of: "https://shop.veil.com/path", with: "https://127.0.0.1/path"),
            valid.replacingOccurrences(of: "https://ads.veil.com/report", with: "https://other.example.net/report"),
            valid.replacingOccurrences(of: "https://ads.veil.com/report", with: "https://other.veil.com/report"),
            valid.replacingOccurrences(of: "\"advertiser\":\"A\"", with: "\"advertiser\":true"),
            valid.replacingOccurrences(of: "\"reportURL\":", with: "\"unexpected\":true,\"reportURL\":")
        ] {
            XCTAssertNil(ContextualAdvertisingCreative.decode(Data(mutation.utf8), configuration: config))
        }
        let oversizedHeadline = String(repeating: "x", count: 121)
        let largeField = valid.replacingOccurrences(of: "\"H\"", with: "\"\(oversizedHeadline)\"")
        XCTAssertNil(ContextualAdvertisingCreative.decode(Data(largeField.utf8), configuration: config))
    }

    func testVerificationEpochRequiresVerifiedFreeEvidenceAndRejectsStaleOrProConflicts() {
        var gate = ContextualAdvertisingVerificationGate()
        let initialEpoch = gate.epoch
        XCTAssertTrue(gate.permitsFree(epoch: initialEpoch, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false),
            "A verified empty current-entitlements scan plus verified inactive status means free")

        let freeScanBeforeUnverifiedEvent = initialEpoch
        let afterUnverifiedEvent = gate.invalidate()
        XCTAssertFalse(gate.permitsFree(epoch: freeScanBeforeUnverifiedEvent, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false),
            "An unverified event must invalidate an older free scan")
        XCTAssertTrue(gate.permitsFree(epoch: afterUnverifiedEvent, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false))

        let backgroundRequest = afterUnverifiedEvent
        let afterBackground = gate.invalidate()
        let afterExternalPro = gate.invalidate()
        XCTAssertFalse(gate.permitsFree(epoch: backgroundRequest, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false),
            "A background request cannot restore free after a later external Pro change")
        XCTAssertFalse(gate.permitsFree(epoch: afterBackground, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false),
            "The older background epoch remains invalid")

        XCTAssertFalse(gate.permitsFree(epoch: afterExternalPro, currentScanVerified: true,
            hasCurrentProEntitlement: true, statusSnapshotVerified: true, statusSuggestsPro: false),
            "A current Pro entitlement must suppress free ads")
        XCTAssertFalse(gate.permitsFree(epoch: afterExternalPro, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: true),
            "Active or grace Pro status conflicts with empty current entitlements")

        let newProScan = gate.invalidate()
        XCTAssertFalse(gate.permitsFree(epoch: newProScan, currentScanVerified: false,
            hasCurrentProEntitlement: false, statusSnapshotVerified: true, statusSuggestsPro: false),
            "An unverified Pro scan cannot produce free eligibility")
        XCTAssertFalse(gate.permitsFree(epoch: newProScan, currentScanVerified: true,
            hasCurrentProEntitlement: false, statusSnapshotVerified: false, statusSuggestsPro: false),
            "An unverified status snapshot cannot prove free eligibility")
    }
}

@MainActor
private final class TestProvider: ContextualAdvertisingProviding {
    enum TestFailure: Error { case failed }
    private let result: ContextualAdvertisingCreative?
    private let error: Error?
    private let pends: Bool
    private(set) var calls = 0
    private var pending: CheckedContinuation<ContextualAdvertisingCreative?, Error>?
    private var startWaiters: [(callNumber: Int, continuation: CheckedContinuation<Void, Never>)] = []

    init(result: ContextualAdvertisingCreative? = nil, error: Error? = nil, pends: Bool = false) {
        self.result = result; self.error = error; self.pends = pends
    }

    func loadCreative(using configuration: ContextualAdvertisingConfiguration) async throws -> ContextualAdvertisingCreative? {
        calls += 1
        let readyWaiters = startWaiters.filter { $0.callNumber <= calls }
        startWaiters.removeAll { $0.callNumber <= calls }
        readyWaiters.forEach { $0.continuation.resume() }
        if pends {
            return try await withCheckedThrowingContinuation { pending = $0 }
        }
        if let error { throw error }
        return result
    }

    func completeFirst(_ result: ContextualAdvertisingCreative?) {
        pending?.resume(returning: result)
        pending = nil
    }

    func waitUntilStarted(callNumber: Int = 1) async {
        guard calls < callNumber else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append((callNumber, continuation))
        }
    }
}
