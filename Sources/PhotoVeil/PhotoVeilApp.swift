import SwiftUI
import AuthenticationServices
import OSLog
import Security

@main
struct PhotoVeilApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var library: VeilLibrary
    @StateObject private var account: VeilAccount
    @StateObject private var subscriptions: VeilSubscriptionStore
    @StateObject private var exportAccess: VeilExportAccess
    @State private var bootstrapped = false
    private static let signposter = OSSignposter(subsystem: "com.maksym1503.veil", category: "Startup")
    init() {
        let local = VeilLibrary()
        var localCommerceTesting = false
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        localCommerceTesting = arguments.contains("-veil-ui-testing") && arguments.contains("-veil-storekit-testing")
        #endif
        let commerce = VeilSubscriptionStore(purchasesPermitted: VeilPublicLinks.privacyPolicy != nil && VeilPublicLinks.terms != nil,
                                             localDevelopmentTesting: localCommerceTesting)
        _subscriptions = StateObject(wrappedValue: commerce)
        _exportAccess = StateObject(wrappedValue: VeilExportAccess(subscriptions: commerce))
        _library = StateObject(wrappedValue: local)
        _account = StateObject(wrappedValue: VeilAccount(library: local))
    }
    var body: some Scene {
        WindowGroup {
            PhotoVeilHome().environmentObject(library).environmentObject(account).environmentObject(subscriptions).environmentObject(exportAccess)
                .task {
                    guard !bootstrapped else { return }
                    bootstrapped = true
                    let interval = Self.signposter.beginInterval("Local preparation")
                    // Session-isolated cleanup cannot remove a newly shared photo.
                    async let cleanup: Void = Task.detached(priority: .utility) { TemporaryPhoto.clearPreviousSession() }.value
                    await library.open(); await library.reload()
                    await cleanup
                    Self.signposter.endInterval("Local preparation", interval)
                    await account.restore(); await account.checkAppleCredential()
                }
                .task { await subscriptions.start() }
                .onReceive(NotificationCenter.default.publisher(for: ASAuthorizationAppleIDProvider.credentialRevokedNotification)) { _ in Task { await account.checkAppleCredential() } }
                .onChange(of: scenePhase) { _, value in subscriptions.invalidateAdvertisingReadiness(); subscriptions.invalidatePreviewReadiness(); exportAccess.refreshUsage(); PrivacyShield.cover(value != .active); account.setActive(value == .active); if value == .active { account.requestSync(); Task { await account.checkAppleCredential() }; Task { await subscriptions.refreshEntitlements(); await subscriptions.refreshOfferEligibility() } } }
        }
    }
}


/// Shared by all user-initiated output paths; never participates in image processing.
@MainActor final class VeilExportAccess: ObservableObject {
    private let subscriptions: VeilSubscriptionStore
    private let allowance: ExportAllowance
    private var checking = false
    @Published private(set) var snapshot: ExportUsageRecord?
    var usage: Int? { snapshot?.completed }
    var freeLimit: Int { snapshot?.limit ?? 1 }
    func refreshUsage() { _ = try? allowance.loadSnapshot(); snapshot = allowance.currentRecord }
    init(subscriptions: VeilSubscriptionStore) {
        self.subscriptions = subscriptions
        let storage = ExportUsageKeychain()
        allowance = ExportAllowance(read: { try storage.read() }, write: { try storage.write($0) })
        _ = try? allowance.loadSnapshot()
        snapshot = allowance.currentRecord
    }
    /// nil asks the caller to present its paywall; errors are distinct from exhaustion.
    func begin() async throws -> UUID? {
        guard !checking else { throw ExportAllowance.Failure.busy }
        checking = true; defer { checking = false; snapshot = allowance.currentRecord }
        let entitled = await subscriptions.refreshEntitlements()
        do { return try allowance.begin(subscribed: entitled) }
        catch ExportAllowance.Failure.subscriptionRequired { return nil }
    }
    @discardableResult func finish(_ id: UUID, succeeded: Bool) -> String? {
        let persisted = allowance.finish(id, succeeded: succeeded)
        snapshot = allowance.currentRecord
        return persisted ? nil
            : "Your photo was exported. Veil couldn’t update the free-export count. Unlock this iPhone and try again before another free export."
    }
    static func message(for error: Error) -> String {
        if error as? ExportAllowance.Failure == .busy { return "Another export is still in progress. Finish or cancel it first." }
        return "Veil couldn’t access the free-export count. Unlock this iPhone and try again. No export has been used."
    }
}

/// Contains only a version, completed operation count and effective limit.
private struct ExportUsageKeychain {
    private let account: String
    init() {
        var name = "free-exports-v1"
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-veil-ui-testing") {
            var scope = UUID().uuidString
            if let index = args.firstIndex(of: "-veil-test-storage-id"), args.indices.contains(index + 1),
               let id = UUID(uuidString: args[index + 1]) { scope = id.uuidString }
            name = "ui-test-exports-" + scope
        }
        #endif
        account = name
    }
    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.maksym1503.veil.export-usage",
         kSecAttrAccount as String: account, kSecAttrSynchronizable as String: false]
    }
    func read() throws -> ExportUsageRecord {
        var lookup = query; lookup[kSecReturnData as String] = true; lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecItemNotFound {
            #if DEBUG
            if let legacy = legacySeedCount {
                let data = Data("{\"version\":1,\"completed\":\(legacy)}".utf8)
                var insert = query
                insert[kSecValueData as String] = data
                insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw ExportAllowance.Failure.storageUnavailable }
                return try ExportUsageRecord.decode(data)
            }
            #endif
            return ExportUsageRecord(completed: 0, limit: 1)
        }
        guard status == errSecSuccess, let data = result as? Data else { throw ExportAllowance.Failure.storageUnavailable }
        return try ExportUsageRecord.decode(data)
    }
    #if DEBUG
    private var legacySeedCount: Int? {
        let args = ProcessInfo.processInfo.arguments
        guard args.contains("-veil-ui-testing"),
              let storageIndex = args.firstIndex(of: "-veil-test-storage-id"), args.indices.contains(storageIndex + 1),
              UUID(uuidString: args[storageIndex + 1]) != nil,
              let seedIndex = args.firstIndex(of: "-veil-legacy-usage"), args.indices.contains(seedIndex + 1),
              let count = Int(args[seedIndex + 1]), (0...2).contains(count) else { return nil }
        return count
    }
    #endif
    func write(_ record: ExportUsageRecord) throws {
        let data = try JSONEncoder().encode(record)
        let attributes: [String: Any] = [kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query; insert.merge(attributes) { _, new in new }
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw ExportAllowance.Failure.storageUnavailable }
        } else if status != errSecSuccess { throw ExportAllowance.Failure.storageUnavailable }
    }
}
