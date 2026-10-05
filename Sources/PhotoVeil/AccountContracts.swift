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
    func restore() async throws { identity = try await auth.restore() }
    func apple(_ proof: AppleIdentityProof) async throws { identity = try await auth.signInApple(proof) }
    func google() async throws { identity = try await auth.signInGoogle() }
    func signOut() async throws { try await auth.signOut(); identity = nil }
    func delete() async throws { try await auth.deleteAccount(); identity = nil }
}
