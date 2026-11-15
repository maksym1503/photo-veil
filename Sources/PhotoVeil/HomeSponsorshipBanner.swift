import SwiftUI

/// Native text only. No image, editor model, metadata, account, or export payload enters this view.
@MainActor
struct HomeSponsorshipBanner: View {
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var advertising: ContextualAdvertisingController
    @State private var consent: ContextualAdvertisingConsent = .unknown
    @State private var showingPrivacy = false
    let homeVisible: Bool
    private let configuration: ContextualAdvertisingConfiguration?

    init(homeVisible: Bool) {
        self.homeVisible = homeVisible
        let configuration = Self.loadConfiguration()
        self.configuration = configuration
        _advertising = StateObject(wrappedValue: ContextualAdvertisingController(
            configuration: configuration,
            provider: configuration == nil ? nil : URLSessionContextualAdvertisingProvider()))
    }

    private var eligible: Bool {
        configuration != nil && homeVisible && scenePhase == .active &&
        subscriptions.contextualAdvertisingEntitlement == .verifiedFree && !showingPrivacy
    }

    var body: some View {
        Group {
            if eligible {
                VStack(alignment: .leading, spacing: 8) {
                    if let creative = advertising.creative {
                        Divider()
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sponsored · \(creative.advertiser)")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(creative.headline).font(.subheadline).lineLimit(3)
                                Link(creative.callToAction, destination: creative.destinationURL)
                                    .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                            }
                            Spacer(minLength: 0)
                            Menu {
                                Button("Why this ad?") { showingPrivacy = true }
                                Link("Report this ad", destination: creative.reportURL)
                                Button("Hide sponsor banners") { consent = .declined; advertising.setConsent(.declined) }
                            } label: {
                                Image(systemName: "ellipsis").frame(width: 44, height: 44)
                            }.accessibilityLabel("Ad information and report")
                        }
                        .accessibilityIdentifier("contextualSponsorBanner")
                    } else {
                        Button("Sponsor privacy") { showingPrivacy = true }
                            .font(.caption).foregroundStyle(.secondary).frame(minHeight: 44)
                    }
                }.padding(.horizontal, 28)
            }
        }
        .task {
            guard configuration != nil else { return }
            // Only Apple's catalog/entitlement APIs run before consent, never an ad request.
            if !subscriptions.subscribed { await subscriptions.loadProduct() }
            synchronize()
        }
        .onChange(of: homeVisible) { _, _ in synchronize() }
        .onChange(of: scenePhase) { _, phase in
            advertising.setSceneActive(false)
            subscriptions.invalidateAdvertisingReadiness()
            synchronize()
            if phase == .active && configuration != nil {
                Task { await subscriptions.refreshEntitlements(); synchronize() }
            }
        }
        .onChange(of: subscriptions.contextualAdvertisingEntitlement) { _, _ in synchronize() }
        .onChange(of: showingPrivacy) { _, _ in synchronize() }
        .onDisappear { advertising.setHomeVisible(false) }
        .sheet(isPresented: $showingPrivacy) {
            if let configuration {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Optional sponsor banners").font(.title2.weight(.semibold))
                            Text("Selected for Veil’s photo-privacy context, never for your photo or editing activity.")
                            Text(ContextualAdvertisingConfiguration.dataDisclosureText)
                            Text("Provider: \(configuration.providerDisplayName)")
                            Link("Provider privacy information", destination: configuration.providerPrivacyURL)
                            if let url = VeilPublicLinks.privacyPolicy { Link("Veil Privacy Policy", destination: url) }
                            Text("Your choice is not saved. You can hide banners or change it here. Editing and your free export allowance work either way.")
                                .font(.footnote).foregroundStyle(.secondary)
                            Button("Allow contextual banners") {
                                consent = .granted(disclosureVersion: configuration.disclosureVersion)
                                advertising.setConsent(consent); showingPrivacy = false
                            }.buttonStyle(.borderedProminent).frame(minHeight: 44)
                            Button("No banners") {
                                consent = .declined; advertising.setConsent(consent); showingPrivacy = false
                            }.frame(minHeight: 44)
                        }.padding(24)
                    }
                    .navigationTitle("Sponsor privacy").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingPrivacy = false } } }
                }
            }
        }
    }

    private func synchronize() {
        advertising.setEntitlement(subscriptions.contextualAdvertisingEntitlement)
        advertising.setHomeVisible(homeVisible && !showingPrivacy)
        advertising.setSceneActive(scenePhase == .active)
    }

    /// Bundled, owner-reviewed configuration only; absent in the current release.
    private static func loadConfiguration() -> ContextualAdvertisingConfiguration? {
        guard let fields = Bundle.main.object(forInfoDictionaryKey: "VeilContextualAdvertising") as? [String: Any],
              fields["Enabled"] as? Bool == true, fields["PrivacyReviewApproved"] as? Bool == true,
              let inventory = fields["InventoryURL"] as? String, let inventoryURL = URL(string: inventory),
              let privacy = fields["ProviderPrivacyURL"] as? String, let privacyURL = URL(string: privacy),
              let report = fields["ReportURL"] as? String, let reportURL = URL(string: report),
              let name = fields["ProviderDisplayName"] as? String,
              let version = fields["DisclosureVersion"] as? String else { return nil }
        return ContextualAdvertisingConfiguration(inventoryURL: inventoryURL, providerPrivacyURL: privacyURL,
            reportURL: reportURL, providerDisplayName: name, disclosureVersion: version,
            appPrivacyPublished: VeilPublicLinks.privacyPolicy != nil, supportPublished: VeilPublicLinks.support != nil)
    }
}
