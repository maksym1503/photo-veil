import Foundation

struct VeilIdentity: Equatable, Sendable {
    let id: UUID
    let provider: String
    var displayName: String?
}
struct AppleIdentityProof: Sendable {
    let idToken: String
    let nonce: String
    let authorizationCode: String
    let displayName: String?
}
protocol VeilAuthentication: Sendable {
    func restore() async throws -> VeilIdentity?
    func signInApple(_ proof: AppleIdentityProof) async throws -> VeilIdentity
    func signInGoogle() async throws -> VeilIdentity
    func signOut() async throws
    func deleteAccount() async throws
}
enum AccountFailure: Error { case unconfigured, invalidIdentity, unavailable, invalidConfiguration }

/// Pure, testable lifecycle; the UI only adapts this state. Backend failures never touch image processing.
@MainActor final class AccountSession {
    private let auth: any VeilAuthentication
    private(set) var identity: VeilIdentity?
    init(auth: any VeilAuthentication) { self.auth = auth }
    private var operationID = UUID()
    private func change(_ operation: () async throws -> VeilIdentity?) async throws {
        let revision = UUID(); operationID = revision
        do {
            let result = try await operation()
            guard operationID == revision else { return }
            identity = result
        } catch {
            guard operationID == revision else { return }
            throw error
        }
    }
    func restore() async throws { try await change { try await auth.restore() } }
    func apple(_ proof: AppleIdentityProof) async throws { try await change { try await auth.signInApple(proof) } }
    func google() async throws { try await change { try await auth.signInGoogle() } }
    func signOut() async throws { try await change { try await auth.signOut(); return nil } }
    func delete() async throws { try await change { try await auth.deleteAccount(); return nil } }
}

/// The public URL scheme never accepts arbitrary authentication payloads through onOpenURL.
enum OAuthCallbackPolicy {
    static func accepts(_ url: URL, expected: URL) -> Bool {
        guard url.scheme == expected.scheme, url.host == expected.host, url.path == expected.path,
              url.fragment == nil, url.user == nil, url.password == nil, url.port == nil, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }
        guard !(components.queryItems ?? []).contains(where: { $0.name == "error" || $0.name == "error_description" }) else { return false }
        let codes = (components.queryItems ?? []).filter { $0.name == "code" }
        return codes.count == 1 && !(codes[0].value ?? "").isEmpty
    }
}

/// Failed consent writes must never silently restore an earlier opt-in in this process.
/// The store remains authoritative across launches; callers disclose a failed write.
struct SyncConsentGate {
    struct Change: Equatable {
        let user: UUID
        let enabled: Bool
        fileprivate let revision = UUID()
    }
    private var latest: Change?
    private var suppressed = Set<UUID>()
    mutating func begin(user: UUID, enabled: Bool) -> Change {
        let change = Change(user: user, enabled: enabled)
        latest = change
        suppressed.insert(user)
        return change
    }
    mutating func complete(_ change: Change, succeeded: Bool, currentUser: UUID?) -> Bool? {
        guard latest == change, currentUser == change.user else { return nil }
        if succeeded && change.enabled { suppressed.remove(change.user) }
        return succeeded && change.enabled
    }
    func permitsRestoration(for user: UUID) -> Bool { !suppressed.contains(user) }
    mutating func invalidate() { latest = nil }
}
