import XCTest
@testable import ImageGeometry

private actor AuthMock: VeilAuthentication {
    var user: VeilIdentity?
    var unavailable = false
    let id = UUID()
    func setUnavailable() { unavailable = true }
    func restore() throws -> VeilIdentity? { if unavailable { throw AccountFailure.unavailable }; return user }
    func signInApple(_ proof: AppleIdentityProof) throws -> VeilIdentity {
        if unavailable { throw AccountFailure.unavailable }
        user = VeilIdentity(id: id, provider: "apple", displayName: proof.displayName); return user!
    }
    func signInGoogle() throws -> VeilIdentity {
        if unavailable { throw AccountFailure.unavailable }
        user = VeilIdentity(id: id, provider: "google", displayName: nil); return user!
    }
    func signOut() { user = nil }
    func deleteAccount() throws { if unavailable { throw AccountFailure.unavailable }; user = nil }
}
final class AccountSessionTests: XCTestCase {
    @MainActor func testOptionalIdentityLifecycleAndMinimalAppleProfile() async throws {
        let auth = AuthMock(), session = AccountSession(auth: AuthMock())
        try await session.restore(); XCTAssertNil(session.identity)
        let apple = AccountSession(auth: auth)
        try await apple.apple(AppleIdentityProof(idToken: "test-only", nonce: "test-only", authorizationCode: "test-only", displayName: nil))
        XCTAssertEqual(apple.identity?.provider, "apple"); XCTAssertNil(apple.identity?.displayName)
        let restored = AccountSession(auth: auth); try await restored.restore(); XCTAssertEqual(restored.identity, apple.identity)
        try await restored.signOut(); XCTAssertNil(restored.identity)
        try await restored.google(); XCTAssertEqual(restored.identity?.provider, "google")
        try await restored.delete(); XCTAssertNil(restored.identity)
    }
    @MainActor func testBackendFailureRetainsSessionForRetry() async throws {
        let auth = AuthMock(), session = AccountSession(auth: auth)
        try await session.google(); let before = session.identity
        await auth.setUnavailable()
        do { try await session.delete(); XCTFail() } catch {}
        XCTAssertEqual(session.identity, before)
    }
}
