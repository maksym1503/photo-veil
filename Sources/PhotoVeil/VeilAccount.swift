import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

@MainActor final class VeilAccount: ObservableObject {
    @Published private(set) var identity: VeilIdentity?
    @Published private(set) var syncEnabled = false
    @Published private(set) var syncStatus = "Stored on this iPhone"
    @Published private(set) var busy = false
    @Published private(set) var lastSync: Date?
    @Published var message: String?
    let auth: SupabaseAuthentication?
    let backendReadiness: BackendReadiness
    private let lifecycle: AccountSession?
    private let library: VeilLibrary
    private var syncTask: Task<Void, Never>?
    private var authEvents: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var syncID = UUID()
    private var pendingSync = false
    private var active = true
    private var consent = SyncConsentGate()

    init(library: VeilLibrary) {
        self.library = library
        let readiness = BackendConfiguration.readiness()
        backendReadiness = readiness
        if let configuration = readiness.configuration {
            let adapter = SupabaseAuthentication(configuration: configuration)
            auth = adapter; lifecycle = AccountSession(auth: adapter)
        } else { auth = nil; lifecycle = nil }
        library.didChange = { [weak self] in self?.requestSync() }
    }
    func restore() async {
        guard let lifecycle else { return }
        do {
            try await lifecycle.restore(); await refreshIdentity()
            if authEvents == nil, let auth {
                authEvents = Task { [weak self] in
                    for await (event, _) in auth.client.authStateChanges {
                        if event == .signedOut {
                            self?.stopSync(); self?.consent.invalidate(); self?.identity = nil; self?.syncEnabled = false
                            self?.syncStatus = "Sign in to resume sync"
                        }
                    }
                }
            }
        }
        catch { message = "Account couldn’t be restored. The editor and local gallery remain available." }
    }
    private func refreshIdentity() async {
        identity = lifecycle?.identity
        if let user = identity?.id, let store = library.store {
            let stored = await store.syncEnabled(for: user)
            guard identity?.id == user else { return }
            syncEnabled = stored && consent.permitsRestoration(for: user)
        }
        else { syncEnabled = false }
        syncStatus = syncEnabled ? "Ready to sync" : "Stored on this iPhone"
        setActive(active); requestSync()
        if let auth, let user = identity?.id {
            Task {
                if let session = try? await auth.client.session,
                   let name = try? await auth.transport.profileName(user: user, token: session.accessToken), identity?.id == user {
                    identity?.displayName = name
                }
            }
        }
    }
    func checkAppleCredential() async {
        guard identity?.provider == "apple", let providerIdentity = auth?.client.currentUser?.identities?.first(where: { $0.provider == "apple" }),
              let user = providerIdentity.identityData?["sub"]?.stringValue else { return }
        let identityID = identity?.id
        let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: user)
        guard identity?.id == identityID else { return }
        if state == .revoked || state == .notFound { await signOut() }
    }
    func apple(_ proof: AppleIdentityProof) async {
        guard let lifecycle, !busy else { return }
        busy = true; defer { busy = false }
        do { try await lifecycle.apple(proof); await refreshIdentity() }
        catch {
            // A provider may already have created the session before a follow-up operation failed.
            try? await lifecycle.restore(); await refreshIdentity()
            message = "Apple sign-in couldn’t finish. Try reconnecting Apple when online. Cloud sync remains optional."
        }
    }
    func google() async {
        guard let lifecycle, !busy else { return }
        busy = true; defer { busy = false }
        do { try await lifecycle.google(); await refreshIdentity() }
        catch {
            try? await lifecycle.restore(); await refreshIdentity()
            message = "Google sign-in couldn’t finish. Try again when online."
        }
    }
    func signOut() async {
        guard let lifecycle, !busy else { return }
        busy = true; defer { busy = false }
        await setSync(false)
        do { try await lifecycle.signOut(); await refreshIdentity() }
        catch { message = "Sign-out couldn’t finish. Try again." }
    }
    func deleteAccount() async {
        guard let lifecycle, let user = identity?.id, !busy else { return }
        busy = true; defer { busy = false }
        guard await setSync(false), identity?.id == user else { return }
        do {
            try await lifecycle.delete(); try? await library.store?.forgetAccount(user); await refreshIdentity()
            message = "Account and cloud gallery deleted. Local gallery kept on this iPhone."
        } catch { message = "Deletion couldn’t finish. Retry online. If you use Apple, reconnect Apple and retry deletion. Local photos remain available." }
    }
    func updateName(_ name: String) async {
        guard let auth, let user = identity?.id, !busy else { return }
        busy = true; defer { busy = false }
        do {
            let session = try await auth.client.session
            guard identity?.id == user else { return }
            try await auth.transport.profile(user: user, displayName: name, token: session.accessToken)
            guard identity?.id == user else { return }
            identity?.displayName = String(name.prefix(80))
        } catch { message = "Your display name couldn’t be updated." }
    }
    @discardableResult func setSync(_ enabled: Bool) async -> Bool {
        stopSync()
        syncEnabled = false
        syncStatus = "Cloud sync is off"
        guard let user = identity?.id else { return !enabled }
        let change = consent.begin(user: user, enabled: enabled)
        guard let store = library.store else {
            message = "Cloud sync is off for this session. The preference couldn’t be saved. Retry before closing Veil."
            return false
        }
        do {
            try await store.setSync(enabled, for: user)
            guard let resolved = consent.complete(change, succeeded: true, currentUser: identity?.id) else { return false }
            syncEnabled = resolved
            syncStatus = resolved ? "Ready to sync" : "Cloud sync is off"
            setActive(active); requestSync()
            return true
        } catch {
            guard consent.complete(change, succeeded: false, currentUser: identity?.id) != nil else { return false }
            message = "Cloud sync is off for this session. The preference couldn’t be saved. Unlock this iPhone and retry before closing Veil."
            return false
        }
    }
    func deleteCloudCopies() async {
        guard let auth, let user = identity?.id, !busy else { return }
        busy = true; defer { busy = false }
        guard await setSync(false), identity?.id == user else { return }
        do {
            let cloud = SupabaseGallery(auth: auth)
            for item in try await cloud.list(user: user) {
                // Persist the explicit keep-local intent before any server-side deletion.
                try await library.store?.retainLocalCopyForCloudDeletion(item.id, for: user)
                try await cloud.delete(user: user, id: item.id)
            }
            message = "Cloud copies deleted. These local photos stay on this iPhone, even if you enable sync again."
        } catch { message = "Cloud deletion couldn’t finish. Retry online; sync remains off." }
    }
    func setActive(_ value: Bool) {
        active = value; retryTask?.cancel(); retryTask = nil
        if !value { stopSync(); return }
        guard syncEnabled else { return }
        retryTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
                self?.requestSync()
            }
        }
    }
    func requestSync() {
        guard active, syncEnabled, let auth, let user = identity?.id, let store = library.store else { return }
        if syncTask != nil { pendingSync = true; return }
        let runID = UUID(); syncID = runID; pendingSync = false; syncStatus = "Syncing processed photos…"
        syncTask = Task {
            do {
                try await CloudSync.run(store: store, cloud: SupabaseGallery(auth: auth), user: user)
                guard !Task.isCancelled, syncID == runID else { return }
                lastSync = Date(); syncStatus = "Sync enabled"
            } catch {
                guard !Task.isCancelled, syncID == runID else { return }
                syncStatus = "Saved locally · sync will retry"
            }
            await library.reload()
            guard syncID == runID else { return }
            syncTask = nil
            if pendingSync { requestSync() }
        }
    }
    private func stopSync() {
        syncID = UUID(); syncTask?.cancel(); syncTask = nil; pendingSync = false
        retryTask?.cancel(); retryTask = nil
    }
}

struct VeilAccountView: View {
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    private var subscriptionsConfigured: Bool { subscriptions.isConfigured }
    @EnvironmentObject private var account: VeilAccount
    @Environment(\.colorScheme) private var colorScheme
    @State private var nonce: String?
    @State private var displayName = ""
    @State private var confirmsSync = false
    @State private var confirmsDelete = false
    @State private var confirmsCloudDelete = false
    // A disabled DEBUG-only rendering fixture exercises the real provider controls without
    // provisioning fake credentials, instantiating an Auth client or simulating a login.
    private var previewsProviderControls: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") && ProcessInfo.processInfo.arguments.contains("-veil-auth-controls-preview")
        #else
        false
        #endif
    }
    var body: some View {
        Group {
            if account.identity == nil && account.auth?.configuration.appleSignInEnabled != true && !previewsProviderControls {
                localAccount
            } else { accountList }
        }
        .navigationTitle("Account").navigationBarTitleDisplayMode(.inline)
        .disabled(account.busy)
        .overlay { if account.busy { ProgressView().padding().background(.regularMaterial, in: Circle()) } }
        .onAppear { displayName = account.identity?.displayName ?? "" }
        .onChange(of: account.identity?.id) { _, _ in displayName = account.identity?.displayName ?? "" }
        .onChange(of: account.identity?.displayName) { old, new in
            if displayName == (old ?? "") { displayName = new ?? "" }
        }
        .confirmationDialog("Enable private sync? Processed photos already saved in your unlinked Veil gallery, thumbnails and edit metadata will upload to your account. Originals will not upload.", isPresented: $confirmsSync, titleVisibility: .visible) {
            Button("Enable sync") { Task { await account.setSync(true) } }
        }
        .confirmationDialog("Delete account and cloud gallery? Local history stays on this iPhone. This cannot be undone. If you subscribe through Apple, deleting your Veil account does not cancel billing. Manage your subscription in App Store account settings.", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) { Task { await account.deleteAccount() } }
        }
        .confirmationDialog("Delete cloud copies? Sync will turn off. Local photos stay on this iPhone.", isPresented: $confirmsCloudDelete, titleVisibility: .visible) {
            Button("Delete cloud copies", role: .destructive) { Task { await account.deleteCloudCopies() } }
        }
        .alert("Account", isPresented: Binding(get: { account.message != nil }, set: { if !$0 { account.message = nil } })) { Button("OK") { account.message = nil } } message: { Text(account.message ?? "") }
    }
    private var localAccount: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ZStack {
                    Circle().fill(.blue.opacity(0.07)).frame(width: 180, height: 180)
                    Circle().strokeBorder(.blue.opacity(0.13), lineWidth: 1).frame(width: 136, height: 136)
                    Image(systemName: "iphone.gen3").font(.system(size: 70, weight: .ultraLight))
                        .foregroundStyle(LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "lock.fill").font(.title3).foregroundStyle(.blue)
                        .offset(x: 42, y: 38)
                }.frame(maxWidth: .infinity).accessibilityHidden(true)
                Text("Your space.\nYour photos.").font(.largeTitle.weight(.semibold))
                Label("On this iPhone", systemImage: "checkmark.shield")
                    .font(.headline).foregroundStyle(.blue).accessibilityIdentifier("localGalleryAvailability")
                Text("Your photos, your choice. Edit, share and keep finished photos in your Private Gallery without creating an account.")
                    .font(.title3).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Divider()
                Label("Only the photos you save", systemImage: "photo.stack").font(.headline)
                Text("Save to Veil keeps finished copies in your Private Gallery. Removing Veil removes this local gallery, so share or save any photos you want to keep first.")
                    .foregroundStyle(.secondary)
                #if DEBUG
                DisclosureGroup("Configuration details") {
                    Text(account.backendReadiness.diagnostic).font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("backendDiagnostic")
                    NavigationLink("Subscription preview") { VeilSubscriptionView() }
                }
                #endif
            }.padding(28)
        }
    }
    private var accountList: some View {
List {
            if let identity = account.identity {
                Section("Account") {
                    LabeledContent("Provider", value: identity.provider.capitalized)
                    TextField("Display name (optional)", text: $displayName).textContentType(.nickname)
                    Button("Save display name") { Task { await account.updateName(displayName) } }
                }
                Section {
                    Toggle("Sync processed gallery", isOn: Binding(get: { account.syncEnabled }, set: { enabled in
                        if enabled { confirmsSync = true } else { Task { await account.setSync(false) } }
                    }))
                    Text(account.syncStatus).font(.footnote).foregroundStyle(.secondary)
                    if let last = account.lastSync { LabeledContent("Last sync this session", value: last.formatted(date: .omitted, time: .shortened)) }
                    if account.syncEnabled { Button("Sync now") { account.requestSync() } }
                    Button("Delete cloud copies", role: .destructive) { confirmsCloudDelete = true }
                } header: { Text("Private cloud gallery") } footer: {
                    Text("Only processed outputs and thumbnails sync. Originals and recognized text stay on this iPhone. Cloud storage uses account access controls; it is not end-to-end encrypted.")
                }
                Section {
                    if identity.provider == "apple", account.auth?.configuration.appleSignInEnabled == true { appleButton }
                    Button("Sign out") { Task { await account.signOut() } }
                    Button("Delete account", role: .destructive) { confirmsDelete = true }
                } footer: { Text("Signing out or deleting your account keeps local history. Delete local history separately in Settings.") }
            } else if account.auth?.configuration.appleSignInEnabled == true || previewsProviderControls {
                Section {
                    Label("Your gallery, across devices", systemImage: "photo.stack").font(.title3.weight(.semibold))
                    Text("Sign in to optionally sync processed photos. Editing and local history work without an account.")
                    if account.auth?.configuration.appleSignInEnabled == true || previewsProviderControls { appleButton.disabled(previewsProviderControls) }
                    Button { Task { await account.google() } } label: {
                        Image(colorScheme == .dark ? "GoogleSignInDark" : "GoogleSignInLight")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .frame(minHeight: 50)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Continue with Google")
                    .accessibilityIdentifier("continueWithGoogle")
                    .disabled(previewsProviderControls)
                    if previewsProviderControls { Text("Sign-in controls preview — authentication is disabled.").font(.footnote) }
                }
            } else {
                Section {
                    Label("On this iPhone", systemImage: "iphone").font(.title3.weight(.semibold))
                        .accessibilityIdentifier("localGalleryAvailability")
                    Text("Your photos, your choice. Edit, share and keep finished photos in your Private Gallery without creating an account.")
                    Text("Your gallery stays on this iPhone. No sign-in is needed to edit or share.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            #if DEBUG
            Section {
                if !subscriptionsConfigured {
                    NavigationLink("Subscription preview") { VeilSubscriptionView() }
                }
                DisclosureGroup("Configuration details") {
                    Text(account.backendReadiness.diagnostic).font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("backendDiagnostic")
                }
            }
            #endif
        }
    }
    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            var bytes = [UInt8](repeating: 0, count: 32)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { account.message = "Apple sign-in couldn’t start."; return }
            let raw = Data(bytes).base64EncodedString(); nonce = raw
            request.nonce = SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
            // Provider email/relay is used by Auth; no duplicate email profile is created.
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            guard let nonce else { return }
            self.nonce = nil
            if case .failure(let error) = result {
                if (error as? ASAuthorizationError)?.code != .canceled { account.message = "Apple sign-in couldn’t complete. Please try again." }
                return
            }
            guard case .success(let authorization) = result,
                  let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let token = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }),
                  let code = credential.authorizationCode.flatMap({ String(data: $0, encoding: .utf8) }) else { return }
            let name = credential.fullName.map { PersonNameComponentsFormatter().string(from: $0) }.flatMap { $0.isEmpty ? nil : $0 }
            Task { await account.apple(AppleIdentityProof(idToken: token, nonce: nonce, authorizationCode: code, displayName: name)) }
        }.signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black).frame(height: 50)
        .accessibilityIdentifier("continueWithApple")
    }
}
