import Foundation

struct BackendConfiguration: Sendable {
    let url: URL
    let publishableKey: String
    let redirect: URL
    static func load(bundle: Bundle = .main) -> BackendConfiguration? {
        guard let file = bundle.url(forResource: "VeilBackend", withExtension: "plist"),
              let data = try? Data(contentsOf: file),
              let dictionary = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let endpoint = dictionary["SupabaseURL"], let url = URL(string: endpoint),
              url.scheme == "https", url.host != nil, url.path.isEmpty || url.path == "/",
              url.query == nil, url.fragment == nil, url.user == nil, url.password == nil,
              let key = dictionary["PublishableKey"], key.hasPrefix("sb_publishable_"), key.count > 20,
              let callback = dictionary["RedirectURL"], let redirect = URL(string: callback),
              redirect.scheme == "veil", redirect.host == "auth", redirect.path == "/callback",
              dictionary["AppleCapabilityEnabled"] == "YES"
        else { return nil }
        return BackendConfiguration(url: url, publishableKey: key, redirect: redirect)
    }
}
