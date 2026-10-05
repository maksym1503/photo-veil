import Foundation

/// Auth refresh/OAuth remains in the SDK. This small REST adapter only transports gallery metadata/files.
final class BackendTransport: @unchecked Sendable {
    let configuration: BackendConfiguration
    private let session: URLSession
    init(configuration: BackendConfiguration) {
        self.configuration = configuration
        let options = URLSessionConfiguration.ephemeral
        options.urlCache = nil; options.httpCookieStorage = nil; options.requestCachePolicy = .reloadIgnoringLocalCacheData
        options.timeoutIntervalForRequest = 30; options.timeoutIntervalForResource = 120
        session = URLSession(configuration: options)
    }
    func authRequest(_ request: URLRequest) async throws -> (Data, URLResponse) { try await session.data(for: request) }
    func request(path: String, method: String, token: String, data: Data? = nil,
                 contentType: String = "application/json", headers: [String: String] = [:], query: [URLQueryItem] = []) async throws -> Data {
        var components = URLComponents(url: configuration.url.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method; request.httpBody = data
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(configuration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
        let (result, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw AccountFailure.unavailable }
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 { throw AccountFailure.invalidIdentity }
            throw AccountFailure.unavailable // Never expose private server payloads in logs/UI.
        }
        return result
    }
    func function(_ name: String, token: String, body: [String: String]) async throws {
        _ = try await request(path: "functions/v1/\(name)", method: "POST", token: token, data: JSONEncoder().encode(body))
    }
    func profile(user: UUID, displayName: String, token: String) async throws {
        let body = ["id": user.uuidString, "display_name": String(displayName.prefix(80))]
        _ = try await request(path: "rest/v1/profiles", method: "POST", token: token,
                             data: JSONEncoder().encode(body), headers: ["Prefer": "resolution=merge-duplicates"])
    }
}
