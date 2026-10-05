import Foundation

struct BackendConfiguration: Equatable, Sendable {
    let url: URL
    let publishableKey: String
    let redirect: URL
    let appleSignInEnabled: Bool
    // Avoid restoring a staging session against a different configured project.
    var authStorageKey: String { "veil.auth.\(url.host?.lowercased() ?? "unconfigured")" }

    static func readiness(bundle: Bundle = .main) -> BackendReadiness {
        guard let file = bundle.url(forResource: "VeilBackend", withExtension: "plist") else { return .missingFile }
        guard let data = try? Data(contentsOf: file) else { return .unreadableFile }
        return parse(data)
    }
    static func parse(_ data: Data) -> BackendReadiness {
        guard let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return .invalidPropertyList
        }
        func text(_ key: String) -> String? { (dictionary[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let endpoint = text("SupabaseURL"), !endpoint.isEmpty else { return .invalidField("SupabaseURL") }
        guard let url = URL(string: endpoint), url.scheme == "https", let host = url.host, !host.isEmpty,
              url.path.isEmpty || url.path == "/", url.query == nil, url.fragment == nil,
              url.user == nil, url.password == nil, url.port == nil else { return .invalidField("SupabaseURL") }
        guard let key = text("PublishableKey"), key.hasPrefix("sb_publishable_"), key.count > 20,
              !key.contains(where: \.isWhitespace) else { return .invalidField("PublishableKey") }
        guard let callback = text("RedirectURL"), let redirect = URL(string: callback),
              redirect.scheme == "veil", redirect.host == "auth", redirect.path == "/callback",
              redirect.query == nil, redirect.fragment == nil, redirect.user == nil,
              redirect.password == nil, redirect.port == nil else { return .invalidField("RedirectURL") }
        let apple: Bool
        if let value = dictionary["AppleCapabilityEnabled"] as? String {
            guard ["YES", "NO"].contains(value) else { return .invalidField("AppleCapabilityEnabled") }
            apple = value == "YES"
        } else if let value = dictionary["AppleCapabilityEnabled"] as? Bool { apple = value }
        else if dictionary["AppleCapabilityEnabled"] == nil { apple = false }
        else { return .invalidField("AppleCapabilityEnabled") }
        return .configured(BackendConfiguration(url: url, publishableKey: key, redirect: redirect, appleSignInEnabled: apple))
    }
}

enum BackendReadiness: Equatable, Sendable {
    case missingFile, unreadableFile, invalidPropertyList, invalidField(String), configured(BackendConfiguration)
    var configuration: BackendConfiguration? { if case .configured(let value) = self { return value }; return nil }
    // Field names and readiness only. Never include keys, tokens, URLs or provider payloads.
    var diagnostic: String {
        switch self {
        case .missingFile: "VeilBackend.plist is absent from the app bundle. No account client was created."
        case .unreadableFile: "VeilBackend.plist could not be read."
        case .invalidPropertyList: "VeilBackend.plist is not a valid configuration dictionary."
        case .invalidField(let name): "Check the \(name) field in VeilBackend.plist."
        case .configured(let value): value.appleSignInEnabled
            ? "Client configuration is present. Apple capability/provider/server setup still requires owner verification."
            : "Client configuration is present. Apple is disabled by AppleCapabilityEnabled; Google setup still requires owner verification."
        }
    }
}
