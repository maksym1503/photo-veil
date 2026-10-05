import Auth
import Foundation

/// The official SDK owns OAuth/PKCE, session renewal and Keychain persistence. No credentials are logged.
final class SupabaseAuthentication: VeilAuthentication, @unchecked Sendable {
    let client: AuthClient
    let configuration: BackendConfiguration
    let transport: BackendTransport
    init(configuration: BackendConfiguration) {
        self.configuration = configuration
        transport = BackendTransport(configuration: configuration)
        client = AuthClient(configuration: .init(url: configuration.url.appendingPathComponent("auth/v1"),
            headers: ["apikey": configuration.publishableKey], flowType: .pkce, redirectToURL: configuration.redirect,
            localStorage: ProtectedAuthStorage(), fetch: { [transport] request in try await transport.authRequest(request) },
            emitLocalSessionAsInitialSession: true))
    }
    func restore() async throws -> VeilIdentity? {
        for await (_, session) in client.authStateChanges {
            return session.map { identity($0.user) }
        }
        return nil
    }
    func signInApple(_ proof: AppleIdentityProof) async throws -> VeilIdentity {
        let session = try await client.signInWithIdToken(credentials: .init(provider: .apple, idToken: proof.idToken, nonce: proof.nonce))
        // Authorization code is needed for server-side Apple revocation on account deletion.
        try await transport.function("apple-credential", token: session.accessToken,
                                     body: ["code": proof.authorizationCode])
        let result = identity(session.user, displayName: proof.displayName)
        if let name = result.displayName { try await transport.profile(user: result.id, displayName: name, token: session.accessToken) }
        return result
    }
    func signInGoogle() async throws -> VeilIdentity {
        let session = try await client.signInWithOAuth(provider: .google, redirectTo: configuration.redirect,
                                                       scopes: "openid email profile", launchFlow: { [configuration] url in
            try await GoogleOAuthPresentation.authenticate(url, callback: configuration.redirect)
        })
        let result = identity(session.user)
        if let name = result.displayName { try await transport.profile(user: result.id, displayName: name, token: session.accessToken) }
        return result
    }
    func signOut() async throws {
        // Local scope clears the SDK session even if the network is unavailable.
        do { try await client.signOut(scope: .local) }
        catch { if client.currentSession != nil { throw error } }
    }
    func deleteAccount() async throws {
        let session = try await client.session
        try await transport.function("delete-account", token: session.accessToken, body: [:])
        do { try await client.signOut(scope: .local) }
        catch { if client.currentSession != nil { throw error } }
    }
    private func identity(_ user: User, displayName: String? = nil) -> VeilIdentity {
        let name = displayName ?? user.userMetadata["full_name"]?.stringValue ?? user.userMetadata["name"]?.stringValue
        return VeilIdentity(id: user.id, provider: user.appMetadata["provider"]?.stringValue ?? "Account", displayName: name)
    }
}
