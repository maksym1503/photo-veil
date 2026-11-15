import Foundation
import Combine
#if canImport(StoreKit)
import StoreKit

/// StoreKit state is independent of the optional Veil/cloud account and export ledger.
@MainActor final class VeilSubscriptionStore: ObservableObject {
    nonisolated static let monthlyID = "vail.pro.monthly"
    nonisolated static let yearlyID = "vail.pro.annual"
    nonisolated static let productIDs: Set<String> = [monthlyID, yearlyID]

    enum Plan: String, CaseIterable, Identifiable {
        case monthly, yearly
        var id: String { rawValue }
        var productID: String { self == .monthly ? Self.monthlyProductID : Self.yearlyProductID }
        private static let monthlyProductID = VeilSubscriptionStore.monthlyID
        private static let yearlyProductID = VeilSubscriptionStore.yearlyID
        var title: String { self == .monthly ? "Monthly" : "Yearly" }
    }

    enum Status: Equatable {
        case inactive, active, canceled, billingGrace, billingRetry, expired
    }

    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var selectedProductID = yearlyID
    @Published private(set) var subscribed = false
    @Published private(set) var previewEntitlement: PreviewEntitlement = .unknown
    private var previewEpoch = PreviewEntitlementEpoch()
    func invalidatePreviewReadiness() {
        previewEpoch.invalidate()
        previewEntitlement = .unknown
        // Native presentation must cover stale frames before SwiftUI reconciles.
        NotificationCenter.default.post(name: .veilPreviewAccessInvalidated, object: nil)
    }
    @Published private(set) var advertisingEntitlementsVerified = false
    private var advertisingCurrentScanVerified = false
    private var advertisingVerification = ContextualAdvertisingVerificationGate()
    func invalidateAdvertisingReadiness() {
        advertisingEntitlementsVerified = false
        advertisingVerification.invalidate()
    }
    /// Advertising is more conservative than export admission: unknown is never free.
    var contextualAdvertisingEntitlement: ContextualAdvertisingEntitlement {
        if subscribed { return .pro }
        if busy { return .busy }
        if loading { return .loading }
        if productLoadError != nil { return .unavailable }
        guard advertisingEntitlementsVerified, hasLoadedProducts,
              products.count == Self.productIDs.count else { return .unknown }
        return .verifiedFree
    }
    @Published private(set) var status: Status = .inactive
    @Published private(set) var busy = false
    @Published private(set) var loading = false
    @Published private(set) var trialEligible = false
    @Published private(set) var hasLoadedProducts = false
    @Published private(set) var productLoadError: String?
    @Published var message: String?

    private let purchasesPermitted: Bool
    private let permitsLocalDevelopmentPurchases: Bool
    private var updates: Task<Void, Never>?
    private var statusUpdates: Task<Void, Never>?
    private var renewalUpdates: Task<Void, Never>?
    private var entitlementRevision = 0
    private var eligibilityRevision = 0
    private var userSelectedPlan = false

    /// Product IDs are compiled into the app. Missing legal destinations block purchase,
    /// while loading, entitlement refresh, and restore remain available.
    var isConfigured: Bool { !Self.productIDs.isEmpty }
    var product: Product? { products[selectedProductID] }
    var canPurchase: Bool { purchasesPermitted || localTestingMayPurchase }
    var localDevelopmentTesting: Bool { localTestingMayPurchase }
    var selectedPlan: Plan { selectedProductID == Self.monthlyID ? .monthly : .yearly }
    var monthlyProduct: Product? { products[Self.monthlyID] }
    var yearlyProduct: Product? { products[Self.yearlyID] }
    var yearlySavingsPercent: Int? {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct,
              let monthlyCurrency = monthly.priceFormatStyle.locale.currency?.identifier,
              let yearlyCurrency = yearly.priceFormatStyle.locale.currency?.identifier,
              monthlyCurrency == yearlyCurrency, monthlyCurrency != "XXX" else { return nil }
        return SubscriptionOfferPolicy.yearlySavings(monthly: monthly.price, yearly: yearly.price)
    }
    var selectedOfferIsThreeDayTrial: Bool {
        guard let offer = product?.subscription?.introductoryOffer else { return false }
        let days = offer.period.unit == .day && offer.periodCount == 1 ? offer.period.value : nil
        return SubscriptionOfferPolicy.hasThreeDayTrial(eligible: trialEligible,
                                                        freeTrial: offer.paymentMode == .freeTrial, days: days)
    }

    #if DEBUG
    private var localTestingMayPurchase: Bool { permitsLocalDevelopmentPurchases }
    #else
    private var localTestingMayPurchase: Bool { false }
    #endif

    init(purchasesPermitted: Bool = false, localDevelopmentTesting: Bool = false) {
        self.purchasesPermitted = purchasesPermitted
        self.permitsLocalDevelopmentPurchases = localDevelopmentTesting
    }

    deinit { updates?.cancel(); statusUpdates?.cancel(); renewalUpdates?.cancel() }

    func start() async {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, !Task.isCancelled else { return }
                guard case .verified(let transaction) = result else {
                    self.invalidateAdvertisingReadiness()
                    self.invalidatePreviewReadiness()
                    continue
                }
                guard
                      Self.productIDs.contains(transaction.productID) else { continue }
                await self.refreshEntitlements()
                await self.refreshTrialEligibility()
                await transaction.finish()
            }
        }
        // Renewal settings, billing issues and expiry can change without a new
        // transaction. Events trigger a scan; they never directly grant access.
        renewalUpdates = Task { [weak self] in
            for await status in Product.SubscriptionInfo.Status.updates {
                guard let self, !Task.isCancelled else { return }
                guard case .verified(let transaction) = status.transaction else {
                    self.invalidateAdvertisingReadiness()
                    self.invalidatePreviewReadiness()
                    continue
                }
                guard
                      Self.productIDs.contains(transaction.productID),
                      transaction.productType == .autoRenewable else { continue }
                await self.refreshEntitlements()
                await self.refreshTrialEligibility()
            }
        }
        await refreshEntitlements()
    }

    @discardableResult func refreshEntitlements() async -> Bool {
        invalidateAdvertisingReadiness()
        invalidatePreviewReadiness()
        let previewRequest = previewEpoch.value
        let advertisingEpoch = advertisingVerification.epoch
        entitlementRevision += 1
        let revision = entitlementRevision
        var entitledIDs = Set<String>()
        var verifiedScan = true
        for await result in Transaction.currentEntitlements {
            if case .unverified = result { verifiedScan = false }
            guard case .verified(let transaction) = result,
                  Self.productIDs.contains(transaction.productID),
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil, !transaction.isUpgraded else { continue }
            entitledIDs.insert(transaction.productID)
        }

        guard entitlementRevision == revision else { return !entitledIDs.isEmpty }
        if previewEpoch.accepts(previewRequest) {
            previewEntitlement = !entitledIDs.isEmpty ? .pro : verifiedScan ? .free : .unknown
        }
        advertisingCurrentScanVerified = verifiedScan
        subscribed = !entitledIDs.isEmpty
        status = subscribed ? .active : .inactive
        statusUpdates?.cancel()
        statusUpdates = Task { [weak self] in
            await self?.refreshStatusDetails(entitledIDs: entitledIDs, revision: revision, advertisingEpoch: advertisingEpoch)
        }
        return !entitledIDs.isEmpty
    }

    private func refreshStatusDetails(entitledIDs: Set<String>, revision: Int, advertisingEpoch: UInt64) async {
        guard let groupID = products.values.compactMap({ $0.subscription?.subscriptionGroupID }).first else { return }
        guard let entries = try? await Product.SubscriptionInfo.status(for: groupID) else { return }
        guard entitlementRevision == revision else { return }

        var nextStatus: Status = subscribed ? .active : .inactive
        for entry in entries {
            guard case .verified(let transaction) = entry.transaction,
                  Self.productIDs.contains(transaction.productID),
                  transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil, !transaction.isUpgraded else { continue }
            switch entry.state {
            case .inGracePeriod:
                guard case .verified(let renewalInfo) = entry.renewalInfo,
                      let graceEnd = renewalInfo.gracePeriodExpirationDate,
                      graceEnd > Date() else { continue }
                if entitledIDs.contains(transaction.productID) { nextStatus = .billingGrace }
            case .inBillingRetryPeriod:
                if !subscribed { nextStatus = .billingRetry }
            case .subscribed:
                if entitledIDs.contains(transaction.productID),
                   case .verified(let renewalInfo) = entry.renewalInfo,
                   !renewalInfo.willAutoRenew {
                    nextStatus = .canceled
                }
            case .expired:
                if entitledIDs.isEmpty { nextStatus = .expired }
            case .revoked:
                if entitledIDs.isEmpty { nextStatus = .expired }
            default:
                break
            }
        }
        guard entitlementRevision == revision else { return }
        status = nextStatus
        let verifiedStatus = entries.allSatisfy {
            guard case .verified = $0.transaction, case .verified = $0.renewalInfo else { return false }
            return true
        }
        advertisingEntitlementsVerified = advertisingVerification.permitsFree(epoch: advertisingEpoch,
            currentScanVerified: advertisingCurrentScanVerified, hasCurrentProEntitlement: !entitledIDs.isEmpty,
            statusSnapshotVerified: verifiedStatus,
            statusSuggestsPro: entries.contains { $0.state == .subscribed || $0.state == .inGracePeriod })
    }

    func select(_ plan: Plan) {
        guard products[plan.productID] != nil else { return }
        userSelectedPlan = true
        selectedProductID = plan.productID
        trialEligible = false
        eligibilityRevision += 1
        let revision = eligibilityRevision
        Task { await refreshTrialEligibility(revision: revision) }
    }

    func loadProduct() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            productLoadError = nil
            let fetched = try await Product.products(for: Self.productIDs)
            var validated: [String: Product] = [:]
            for item in fetched where item.type == .autoRenewable {
                guard let period = item.subscription?.subscriptionPeriod else { continue }
                switch (item.id, period.unit, period.value) {
                case (Self.monthlyID, .month, 1), (Self.yearlyID, .year, 1):
                    validated[item.id] = item
                default:
                    continue
                }
            }
            let groups = Set(validated.values.compactMap { $0.subscription?.subscriptionGroupID })
            guard groups.count <= 1 else {
                products = [:]
                hasLoadedProducts = true
                productLoadError = "Plans aren’t configured together. Please try again later."
                return
            }
            products = validated
            hasLoadedProducts = true
            if !userSelectedPlan {
                selectedProductID = validated[Self.yearlyID] != nil ? Self.yearlyID : Self.monthlyID
            } else if validated[selectedProductID] == nil {
                selectedProductID = validated[Self.yearlyID] != nil ? Self.yearlyID : Self.monthlyID
            }
            await refreshTrialEligibility()
            await refreshEntitlements()
            if validated.isEmpty {
                productLoadError = "Plans aren’t available right now. Check your connection and try again."
            }
        } catch {
            hasLoadedProducts = true
            productLoadError = "The App Store couldn’t load the plans. Check your connection and try again."
        }
    }

    func refreshOfferEligibility() async { await refreshTrialEligibility() }

    private func refreshTrialEligibility() async {
        trialEligible = false
        eligibilityRevision += 1
        await refreshTrialEligibility(revision: eligibilityRevision)
    }

    private func refreshTrialEligibility(revision: Int) async {
        guard let subscription = product?.subscription else { trialEligible = false; return }
        let eligible = await Product.SubscriptionInfo.isEligibleForIntroOffer(for: subscription.subscriptionGroupID)
        guard eligibilityRevision == revision,
              products[selectedProductID]?.subscription?.subscriptionGroupID == subscription.subscriptionGroupID else { return }
        trialEligible = eligible
    }

    func purchase() async {
        guard canPurchase, let product, !busy else {
            if !canPurchase { message = "Purchases aren’t available until Veil’s Terms of Use and Privacy Policy are published." }
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result,
                      transaction.productID == product.id,
                      Self.productIDs.contains(transaction.productID) else {
                    message = "Apple couldn’t verify this purchase. Restore Purchases to check access."; return
                }
                let entitled = await refreshEntitlements()
                await refreshTrialEligibility()
                await transaction.finish()
                if !entitled { message = "Apple is updating your subscription. Restore Purchases if access doesn’t appear." }
            case .pending:
                message = "Your purchase is awaiting approval. Access updates when Apple confirms it."
            case .userCancelled:
                break
            @unknown default:
                message = "The purchase hasn’t completed. Please try again later."
            }
        } catch {
            message = "The purchase couldn’t finish. Please try again."
        }
    }

    func restore() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            let entitled = await refreshEntitlements()
            await refreshTrialEligibility()
            message = entitled ? "Your subscription has been restored." : "No active Veil subscription was found for this Apple Account."
        } catch {
            message = "Purchases couldn’t be restored. Check your connection and try again."
        }
    }
}
#endif
