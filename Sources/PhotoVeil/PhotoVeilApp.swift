import SwiftUI
import AuthenticationServices

@main
struct PhotoVeilApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library: VeilLibrary
    @StateObject private var account: VeilAccount
    init() {
        TemporaryPhoto.clearPreviousSession()
        let local = VeilLibrary()
        _library = StateObject(wrappedValue: local)
        _account = StateObject(wrappedValue: VeilAccount(library: local))
    }
    var body: some Scene {
        WindowGroup {
            PhotoVeilHome().environmentObject(library).environmentObject(account)
                .task { await library.open(); await library.reload(); await account.restore(); await account.checkAppleCredential() }
                .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification)) { _ in Task { await account.checkAppleCredential() } }
                .onChange(of: scenePhase) { _, value in PrivacyShield.cover(value != .active); account.setActive(value == .active); if value == .active { account.requestSync(); Task { await account.checkAppleCredential() } } }
        }
    }
}
