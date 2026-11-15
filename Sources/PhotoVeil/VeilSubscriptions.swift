import SwiftUI
import StoreKit

struct VeilSubscriptionView: View {
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    @Environment(\.dismiss) private var dismiss
    @State private var managesSubscription = false

    private var selectedProduct: Product? { subscriptions.product }
    private var periodName: String { subscriptions.selectedPlan == .yearly ? "year" : "month" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero
                benefits
                if subscriptions.subscribed {
                    subscriptionStatus
                } else {
                    if subscriptions.status == .billingRetry || subscriptions.status == .expired {
                        subscriptionStatus
                    }
                    planPicker
                    purchaseDetails
                    purchaseButton
                }
                legalActions
                Button("Restore Purchases") { Task { await subscriptions.restore() } }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .modifier(VeilActionStyle())
                    .accessibilityIdentifier("subscriptionRestore")
                #if DEBUG
                if subscriptions.localDevelopmentTesting {
                    Label("Development StoreKit testing", systemImage: "hammer.fill")
                        .font(.footnote.weight(.semibold)).foregroundStyle(.orange)
                        .accessibilityIdentifier("subscriptionDevelopmentNotice")
                    Text("Local purchases require a StoreKit configuration attached to the active Xcode scheme. This label does not confirm that a local purchase environment is active.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                #endif
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 24).padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Veil Pro").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
                    .accessibilityIdentifier("subscriptionClose")
            }
        }
        .disabled(subscriptions.busy)
        .overlay {
            if subscriptions.busy {
                ProgressView().padding(18).background(.regularMaterial, in: Circle())
            }
        }
        .manageSubscriptionsSheet(isPresented: $managesSubscription)
        .task {
            await subscriptions.loadProduct()
            await subscriptions.refreshEntitlements()
        }
        .alert("Veil Pro", isPresented: Binding(
            get: { subscriptions.message != nil },
            set: { if !$0 { subscriptions.message = nil } }
        )) {
            Button("OK") { subscriptions.message = nil }
        } message: {
            Text(subscriptions.message ?? "")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.cyan)
                .accessibilityHidden(true)
            Text("More moments.\nJust as private.")
                .font(.largeTitle.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            benefit("Unlimited protected photo exports", symbol: "checkmark.shield")
            benefit("Edit free, then export privately with Veil Pro", symbol: "square.stack.3d.up")
            Text("Photo processing stays on your iPhone. No Veil account is required.")
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func benefit(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.body.weight(.medium))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a plan").font(.headline)
            ForEach(VeilSubscriptionStore.Plan.allCases) { plan in
                planRow(plan)
            }
            if subscriptions.loading {
                ProgressView("Loading plans…").frame(maxWidth: .infinity, alignment: .leading)
            } else if subscriptions.hasLoadedProducts && subscriptions.products.isEmpty {
                Text(subscriptions.productLoadError ?? "Plans aren’t available right now. Try again when you’re online.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Try Again") { Task { await subscriptions.loadProduct() } }
                    .accessibilityIdentifier("subscriptionRetry")
            }
        }
    }

    @ViewBuilder private func planRow(_ plan: VeilSubscriptionStore.Plan) -> some View {
        if let product = subscriptions.products[plan.productID] {
            let selected = subscriptions.selectedPlan == plan
            Button { subscriptions.select(plan) } label: {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title).font(.headline)
                        if plan == .yearly, let savings = subscriptions.yearlySavingsPercent {
                            Text("Best value · Save \(savings)%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text("\(product.displayPrice) / \(plan == .yearly ? "year" : "month")")
                            .font(.subheadline.weight(.medium))
                        if plan == .yearly, let monthlyEquivalent = monthlyEquivalentText {
                            Text("About \(monthlyEquivalent) per month")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.title2).foregroundStyle(selected ? Color.accentColor : Color.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                .contentShape(RoundedRectangle(cornerRadius: 18))
                .background(selected ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.18), lineWidth: selected ? 1.5 : 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(planAccessibilityLabel(plan, product: product))
            .accessibilityValue(selected ? "Selected" : "Not selected")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier(plan == .yearly ? "subscriptionPlanYearly" : "subscriptionPlanMonthly")
        } else {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).font(.headline)
                    Text(subscriptions.loading || !subscriptions.hasLoadedProducts ? "Loading price…" : "Currently unavailable")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16).frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            .accessibilityElement(children: .combine)
        }
    }

    private func planAccessibilityLabel(_ plan: VeilSubscriptionStore.Plan, product: Product) -> String {
        var label = "\(plan.title), \(product.displayPrice) per \(plan == .yearly ? "year" : "month")"
        if plan == .yearly, let savings = subscriptions.yearlySavingsPercent {
            label += ", Best value, save \(savings) percent compared with twelve monthly payments"
        }
        return label
    }

    private var monthlyEquivalentText: String? {
        guard let yearly = subscriptions.yearlyProduct else { return nil }
        return yearly.priceFormatStyle.format(yearly.price / 12)
    }

    private var purchaseDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            if subscriptions.selectedOfferIsThreeDayTrial {
                Text("3 days free, then \(selectedProduct?.displayPrice ?? "") / \(periodName)")
                    .font(.title3.weight(.semibold))
                Text("Your free trial lasts 3 days. After the trial, your subscription renews at the displayed price each \(periodName) until you cancel. Payment is charged to your Apple Account. Manage or cancel in App Store account settings.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else if let selectedProduct {
                Text("\(selectedProduct.displayPrice) / \(periodName)")
                    .font(.title3.weight(.semibold))
                Text("Renews automatically each \(periodName) at the displayed price until you cancel. Payment is charged to your Apple Account. Manage or cancel in App Store account settings.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if !subscriptions.canPurchase {
                Label("Purchases are unavailable until the Terms of Use and Privacy Policy are published.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var purchaseButton: some View {
        Button {
            Task { await subscriptions.purchase() }
        } label: {
            Text(purchaseTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .modifier(VeilActionStyle(prominent: true))
        .disabled(selectedProduct == nil || !subscriptions.canPurchase)
        .accessibilityIdentifier("subscriptionPurchase")
    }

    private var purchaseTitle: String {
        if subscriptions.selectedOfferIsThreeDayTrial { return "Start 3-Day Free Trial" }
        guard let selectedProduct else { return "Plan unavailable" }
        return "Subscribe · \(selectedProduct.displayPrice) / \(periodName)"
    }

    private var legalActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subscription terms").font(.headline)
            if let url = VeilPublicLinks.terms {
                Link("Terms of Use", destination: url)
            } else {
                Button("Terms of Use unavailable") { subscriptions.message = "Veil’s Terms of Use haven’t been published yet." }
                    .disabled(true)
                    .accessibilityIdentifier("subscriptionTermsUnavailable")
            }
            if let url = VeilPublicLinks.privacyPolicy {
                Link("Privacy Policy", destination: url)
            } else {
                Text("Privacy Policy awaiting publication")
                    .font(.footnote).foregroundStyle(.secondary)
                    .accessibilityIdentifier("subscriptionPrivacyUnavailable")
            }
            Text("Subscriptions are managed through your Apple Account. Cancel anytime in App Store account settings.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var subscriptionStatus: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(statusTitle, systemImage: statusSymbol)
                .font(.headline)
            Text(statusDescription)
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if subscriptions.subscribed {
                Button("Manage Subscription") { managesSubscription = true }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .modifier(VeilActionStyle(prominent: true))
                    .accessibilityIdentifier("subscriptionManage")
            }
        }
        .padding(18)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
    }

    private var statusTitle: String {
        switch subscriptions.status {
        case .canceled: "Subscription active · won’t renew"
        case .billingGrace: "Subscription active · billing grace period"
        case .billingRetry: "Billing needs attention"
        case .expired: "Subscription expired"
        case .active: "Subscription active"
        case .inactive: "Subscription status unavailable"
        }
    }

    private var statusDescription: String {
        switch subscriptions.status {
        case .canceled: "Your access remains active through the current billing period. You can renew or review billing in your Apple Account."
        case .billingGrace: "Apple is allowing continued access while it retries your payment. Update your payment method in your Apple Account to keep the subscription active."
        case .billingRetry: "Apple couldn’t renew the subscription. Review your payment method in your Apple Account to restore access."
        case .expired: "This subscription is no longer active. Choose a plan to subscribe again."
        case .active: "Your Veil Pro subscription is active. Manage or cancel it through your Apple Account."
        case .inactive: "No active subscription was found for this Apple Account."
        }
    }

    private var statusSymbol: String {
        switch subscriptions.status {
        case .billingGrace, .billingRetry: "creditcard.trianglebadge.exclamationmark"
        case .expired: "clock.badge.xmark"
        default: "checkmark.seal"
        }
    }
}
