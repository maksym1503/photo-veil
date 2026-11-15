#if os(iOS)
import XCTest
import StoreKit
import StoreKitTest
import Combine
@testable import ImageGeometry

/// Real Apple local StoreKit transactions; no local flag substitutes for verification.
final class StoreKitSubscriptionTests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    @MainActor private func session() async throws -> SKTestSession {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "VeilLocal", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        resetSettings(session); session.clearTransactions()
        let purchaseError = await session.simulatedError(forAPI: .purchase)
        XCTAssertNil(purchaseError)
        // Native product lookup is the activation gate. A nil error override can
        // silently succeed even when activation fails (and is invalid on 26.1).
        let products = try await Product.products(for: VeilSubscriptionStore.productIDs)
        XCTAssertEqual(Set(products.map(\.id)), Set(VeilSubscriptionStore.productIDs))
        return session
    }
    @MainActor private func resetSettings(_ session: SKTestSession) {
        session.resetToDefaultState()
        session.disableDialogs = true; session.timeRate = .realTime
        session.storefront = "POL"; session.locale = Locale(identifier: "pl_PL")
    }
    @MainActor private func verifiedTransaction(_ productID: String) async throws -> StoreKit.Transaction {
        let latest = await StoreKit.Transaction.latest(for: productID)
        let result = try XCTUnwrap(latest)
        guard case .verified(let transaction) = result else {
            XCTFail("Apple must verify the native local transaction")
            throw NSError(domain: "VeilStoreKitTests", code: 1)
        }
        XCTAssertEqual(transaction.environment, .xcode)
        XCTAssertEqual(transaction.productID, productID)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: transaction.jsonRepresentation) as? [String: Any])
        XCTAssertEqual(payload["bundleId"] as? String, "com.maksym1503.veil")
        return transaction
    }
    @MainActor private func assertTrial(_ transaction: StoreKit.Transaction) throws {
        XCTAssertEqual(transaction.offerType, .introductory)
        let expiration = try XCTUnwrap(transaction.expirationDate)
        XCTAssertEqual(expiration.timeIntervalSince(transaction.purchaseDate), 3 * 24 * 60 * 60, accuracy: 1)
        if #available(iOS 17.2, *) { XCTAssertEqual(transaction.offer?.paymentMode, .freeTrial) }
    }
    /// SKTestSession mutations return before StoreKit publishes their signed updates.
    @MainActor private func expectAccessRemoved(_ store: VeilSubscriptionStore, productID: String,
                                                revoked: Bool = false, mutation: () throws -> Void) async throws {
        XCTAssertTrue(store.subscribed, "The mutation must remove an existing entitlement")
        let removed = expectation(description: "Verified StoreKit update removes access")
        let previewRemoved = expectation(description: "Verified expired access marks exhausted previews")
        let previewObserver = store.$previewEntitlement.filter { $0 == .free }.prefix(1).sink { value in
            XCTAssertEqual(PremiumPreviewState.resolve(completed: 2, limit: 2, entitlement: value), .exhausted)
            previewRemoved.fulfill()
        }
        defer { previewObserver.cancel() }
        var mutationStarted = false
        let observer = store.$subscribed.dropFirst().filter { !$0 && mutationStarted }.prefix(1)
            .sink { _ in removed.fulfill() }
        defer { observer.cancel() }
        mutationStarted = true
        try mutation()
        await fulfillment(of: [removed, previewRemoved], timeout: 10)
        let transaction = try await verifiedTransaction(productID)
        if revoked { XCTAssertNotNil(transaction.revocationDate) }
        else { XCTAssertLessThanOrEqual(try XCTUnwrap(transaction.expirationDate), Date()) }
        let entitled = await store.refreshEntitlements()
        XCTAssertFalse(entitled); XCTAssertFalse(store.subscribed)
    }
    @MainActor func testMonthlyTrialRenewalCancellationAndExpiration() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.start(); await store.loadProduct()
        XCTAssertEqual(store.products.count, 2)
        store.select(.monthly); await store.refreshOfferEligibility()
        XCTAssertEqual(store.selectedProductID, VeilSubscriptionStore.monthlyID)
        XCTAssertTrue(store.selectedOfferIsThreeDayTrial)
        await store.purchase()
        XCTAssertTrue(store.subscribed)
        let trial = try await verifiedTransaction(VeilSubscriptionStore.monthlyID)
        XCTAssertEqual(store.contextualAdvertisingEntitlement, .pro, "A verified trial is ad-free")
        try assertTrial(trial)
        // Verify the paid native state through the app's reconciliation boundary.
        // Transaction.updates does not promise broadcast to a second test iterator
        // while the app also observes/finishes the same transactions.
        let renewal = expectation(description: "Apple provides a verified paid monthly renewal")
        var mutationStarted = false
        var renewedObserved = false
        var checks: [Task<Void, Never>] = []
        func inspectRenewal() async {
            guard mutationStarted, !renewedObserved, !Task.isCancelled,
                  let result = await StoreKit.Transaction.latest(for: VeilSubscriptionStore.monthlyID),
                  case .verified(let transaction) = result,
                  !Task.isCancelled, !renewedObserved,
                  transaction.productID == VeilSubscriptionStore.monthlyID,
                  transaction.environment == .xcode,
                  transaction.id != trial.id,
                  transaction.offerType == nil,
                  transaction.revocationDate == nil,
                  let expiration = transaction.expirationDate, expiration > Date() else { return }
            renewedObserved = true
            renewal.fulfill()
        }
        // Include true-to-true emissions: an entitled trial renews into an entitled
        // paid period. Do not require an artificial access loss or a timer.
        let reconciled = store.$subscribed.dropFirst().sink { _ in
            guard mutationStarted else { return }
            checks.append(Task { @MainActor in await inspectRenewal() })
        }
        defer { reconciled.cancel(); checks.forEach { $0.cancel() } }
        mutationStarted = true
        try session.forceRenewalOfSubscription(productIdentifier: VeilSubscriptionStore.monthlyID)
        await inspectRenewal()
        await fulfillment(of: [renewal], timeout: 10)
        let renewed = try await verifiedTransaction(VeilSubscriptionStore.monthlyID)
        XCTAssertNotEqual(renewed.id, trial.id)
        XCTAssertNil(renewed.offerType)
        XCTAssertGreaterThan(try XCTUnwrap(renewed.expirationDate), Date())
        var hasRenewedEntitlement = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == VeilSubscriptionStore.monthlyID,
               transaction.id == renewed.id, transaction.environment == .xcode {
                hasRenewedEntitlement = true
            }
        }
        XCTAssertTrue(hasRenewedEntitlement, "The paid renewal must be Apple's current entitlement")
        await store.refreshEntitlements(); XCTAssertTrue(store.subscribed)
        let canceled = expectation(description: "Apple reports renewal cancellation")
        let observer = store.$status.filter { $0 == .canceled }.prefix(1).sink { _ in canceled.fulfill() }
        defer { observer.cancel() }
        try session.disableAutoRenewForTransaction(identifier: UInt(renewed.id))
        await store.refreshEntitlements()
        await fulfillment(of: [canceled], timeout: 10)
        XCTAssertTrue(store.subscribed, "Cancellation keeps paid access until expiration")
        try await expectAccessRemoved(store, productID: VeilSubscriptionStore.monthlyID) {
            try session.expireSubscription(productIdentifier: VeilSubscriptionStore.monthlyID)
        }
    }
    @MainActor func testYearlyPurchaseRestartRestoreAndSharedTrialEligibility() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.loadProduct()
        _ = try XCTUnwrap(store.monthlyProduct); _ = try XCTUnwrap(store.yearlyProduct)
        XCTAssertEqual(store.selectedProductID, VeilSubscriptionStore.yearlyID)
        XCTAssertTrue(store.selectedOfferIsThreeDayTrial)
        XCTAssertEqual(store.yearlySavingsPercent, 36)
        XCTAssertEqual(Set(store.products.keys), Set(["vail.pro.monthly", "vail.pro.annual"]))
        XCTAssertFalse(VeilSubscriptionStore.productIDs.contains("vail.pro.yearly"), "Obsolete cross-group product must not grant Pro")
        let obsoleteProducts = try await Product.products(for: ["vail.pro.yearly"])
        XCTAssertTrue(obsoleteProducts.isEmpty, "Only the canonical annual product is offered by the test configuration")
        await store.purchase(); XCTAssertTrue(store.subscribed)
        try assertTrial(try await verifiedTransaction(VeilSubscriptionStore.yearlyID))
        let restarted = VeilSubscriptionStore() // Missing legal configuration must not block access.
        await restarted.start(); XCTAssertTrue(restarted.subscribed)
        func expectCleanPreview(_ action: () async -> Void) async {
            let verified = expectation(description: "Current verified Pro produces a clean preview")
            let observer = restarted.$previewEntitlement.dropFirst().filter { $0 == .pro }.prefix(1).sink { value in
                XCTAssertEqual(PremiumPreviewState.resolve(completed: 2, limit: 2, entitlement: value), .clean)
                verified.fulfill()
            }
            defer { observer.cancel() }
            await action()
            await fulfillment(of: [verified], timeout: 10)
        }
        await expectCleanPreview { await restarted.restore() }
        XCTAssertTrue(restarted.subscribed)
        XCTAssertTrue(restarted.products.isEmpty, "Restored previews must not wait for catalog loading")
        restarted.invalidatePreviewReadiness()
        XCTAssertEqual(restarted.previewEntitlement, .unknown)
        XCTAssertEqual(PremiumPreviewState.resolve(completed: 2, limit: 2, entitlement: restarted.previewEntitlement), .checking)
        await expectCleanPreview { await restarted.refreshEntitlements() }
        XCTAssertEqual(restarted.contextualAdvertisingEntitlement, .pro, "Restored Pro is ad-free before catalog loading")
        await restarted.loadProduct(); restarted.select(.monthly)
        await restarted.refreshOfferEligibility()
        XCTAssertEqual(restarted.selectedProductID, VeilSubscriptionStore.monthlyID)
        XCTAssertFalse(restarted.selectedOfferIsThreeDayTrial, "One introductory offer per group")
    }
    @MainActor func testListenerUnlocksExternalPurchaseAndRefundRevokesAccess() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore()
        await store.start(); await store.loadProduct()
        _ = try XCTUnwrap(store.monthlyProduct); _ = try XCTUnwrap(store.yearlyProduct)
        XCTAssertFalse(store.subscribed)
        let changed = expectation(description: "Verified transaction update unlocks Pro")
        let observer = store.$subscribed.filter { $0 }.prefix(1).sink { _ in changed.fulfill() }
        let transaction = try await session.buyProduct(identifier: VeilSubscriptionStore.yearlyID)
        await fulfillment(of: [changed], timeout: 10)
        withExtendedLifetime(observer) {}
        XCTAssertTrue(store.subscribed)
        _ = try await verifiedTransaction(VeilSubscriptionStore.yearlyID)
        try await expectAccessRemoved(store, productID: VeilSubscriptionStore.yearlyID, revoked: true) {
            try session.refundTransaction(identifier: UInt(transaction.id))
        }
    }
    @MainActor func testPurchaseCancellationFailurePendingAndMissingLegalLinks() async throws {
        let privacy = Bundle.main.object(forInfoDictionaryKey: "VeilPrivacyPolicyURL") as? String
        let support = Bundle.main.object(forInfoDictionaryKey: "VeilSupportURL") as? String
        XCTAssertEqual(privacy, "https://veil-legal.pages.dev/privacy")
        XCTAssertEqual(support, "https://veil-legal.pages.dev/support")
        let configured = VeilSubscriptionStore(purchasesPermitted: privacy == "https://veil-legal.pages.dev/privacy")
        XCTAssertTrue(configured.canPurchase, "Approved bundled legal links open the production legal gate")
        let session = try await session(); defer { session.clearTransactions() }
        let unavailable = VeilSubscriptionStore()
        await unavailable.loadProduct(); XCTAssertFalse(unavailable.canPurchase)
        await unavailable.purchase(); XCTAssertFalse(unavailable.subscribed)
        XCTAssertTrue(session.allTransactions().isEmpty)
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.loadProduct()
        _ = try XCTUnwrap(store.monthlyProduct); _ = try XCTUnwrap(store.yearlyProduct)
        try await session.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)
        await store.purchase(); XCTAssertFalse(store.subscribed)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
        await store.purchase(); XCTAssertFalse(store.subscribed); XCTAssertNotNil(store.message)
        resetSettings(session)
        session.askToBuyEnabled = true
        await store.purchase(); XCTAssertFalse(store.subscribed)
        XCTAssertTrue(store.message?.contains("approval") == true)
        XCTAssertFalse(store.busy)
    }
    @MainActor func testUnverifiedTransactionNeverUnlocksProAndProductLoadingFailsGracefully() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.loadProduct()
        _ = try XCTUnwrap(store.monthlyProduct); _ = try XCTUnwrap(store.yearlyProduct)
        try await session.setSimulatedError(.verification(.invalidSignature), forAPI: .verification)
        await store.purchase(); XCTAssertFalse(store.subscribed)
        let transactionIDs = session.allTransactions().map(\.identifier)
        resetSettings(session)
        XCTAssertEqual(session.allTransactions().map(\.identifier), transactionIDs, "Resetting errors must preserve purchases")
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        let offline = VeilSubscriptionStore()
        await offline.loadProduct(); XCTAssertTrue(offline.products.isEmpty); XCTAssertNotNil(offline.productLoadError)
    }
    @MainActor func testBillingGraceExpiresUsingNativeTimeAcceleration() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.start(); await store.loadProduct()
        _ = try XCTUnwrap(store.yearlyProduct)
        // Establish initial access before Apple's accelerated clock can expire it.
        // Product loading and purchase latency must not spend the grace window.
        await store.purchase(); XCTAssertTrue(store.subscribed)
        let initial = try await verifiedTransaction(VeilSubscriptionStore.yearlyID)
        try assertTrial(initial)
        let grace = expectation(description: "Native clock enters verified billing grace with access")
        let expired = expectation(description: "Native clock exhausts grace and removes access")
        var sawGraceWithAccess = false
        let graceObserver = store.$status.filter { $0 == .billingGrace }.prefix(1).sink { _ in
            XCTAssertTrue(store.subscribed)
            XCTAssertEqual(store.contextualAdvertisingEntitlement, .pro, "Verified grace remains ad-free")
            sawGraceWithAccess = store.subscribed
            grace.fulfill()
        }
        let expiryObserver = store.$subscribed.dropFirst().filter { !$0 && sawGraceWithAccess }.prefix(1)
            .sink { _ in expired.fulfill() }
        defer { graceObserver.cancel(); expiryObserver.cancel() }
        session.shouldEnterBillingRetryOnRenewal = true
        session.billingGracePeriodIsEnabled = true
        session.timeRate = .oneRenewalEveryTwoSeconds
        try session.forceRenewalOfSubscription(productIdentifier: VeilSubscriptionStore.yearlyID)
        // Let Apple's documented native clock run; no sleeps, calendar guesses or polling.
        await fulfillment(of: [grace, expired], timeout: 10, enforceOrder: true)
        let transaction = try await verifiedTransaction(VeilSubscriptionStore.yearlyID)
        XCTAssertLessThanOrEqual(try XCTUnwrap(transaction.expirationDate), Date())
        let entitled = await store.refreshEntitlements()
        XCTAssertFalse(entitled); XCTAssertFalse(store.subscribed)
    }
    @MainActor func testBillingRetryWithoutGraceRemovesAccess() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        session.billingGracePeriodIsEnabled = false
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.start(); await store.loadProduct(); _ = try XCTUnwrap(store.yearlyProduct)
        await store.purchase(); XCTAssertTrue(store.subscribed)
        _ = try await verifiedTransaction(VeilSubscriptionStore.yearlyID)
        session.shouldEnterBillingRetryOnRenewal = true
        let retry = expectation(description: "Verified billing retry without grace")
        let observer = store.$status.filter { $0 == .billingRetry }.prefix(1).sink { _ in retry.fulfill() }
        try session.forceRenewalOfSubscription(productIdentifier: VeilSubscriptionStore.yearlyID)
        await store.refreshEntitlements()
        await fulfillment(of: [retry], timeout: 10)
        withExtendedLifetime(observer) {}
        let entitled = await store.refreshEntitlements()
        XCTAssertFalse(entitled); XCTAssertFalse(store.subscribed)
    }
    @MainActor func testConcurrentRefreshReturnsVerifiedAdmissionResult() async throws {
        let session = try await session(); defer { session.clearTransactions() }
        let store = VeilSubscriptionStore(purchasesPermitted: true)
        await store.start(); await store.loadProduct(); _ = try XCTUnwrap(store.yearlyProduct)
        await store.purchase(); XCTAssertTrue(store.subscribed)
        _ = try await verifiedTransaction(VeilSubscriptionStore.yearlyID)
        async let first = store.refreshEntitlements()
        async let second = store.refreshEntitlements()
        let active = await [first, second]
        XCTAssertEqual(active, [true, true])
        try await expectAccessRemoved(store, productID: VeilSubscriptionStore.yearlyID) {
            try session.expireSubscription(productIdentifier: VeilSubscriptionStore.yearlyID)
        }
        async let third = store.refreshEntitlements()
        async let fourth = store.refreshEntitlements()
        let expired = await [third, fourth]
        XCTAssertEqual(expired, [false, false])
    }

}
#endif
