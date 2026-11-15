import Combine
import CoreFoundation
import Darwin
import Foundation

/// Pure epoch gate for async StoreKit verification results. It grants no access and stores no
/// entitlement; callers still need a current, verified free result and verified status snapshot.
struct ContextualAdvertisingVerificationGate: Sendable {
    private(set) var epoch: UInt64 = 0

    @discardableResult
    mutating func invalidate() -> UInt64 {
        epoch += 1
        return epoch
    }

    func permitsFree(epoch capturedEpoch: UInt64,
                     currentScanVerified: Bool,
                     hasCurrentProEntitlement: Bool,
                     statusSnapshotVerified: Bool,
                     statusSuggestsPro: Bool) -> Bool {
        capturedEpoch == epoch
            && currentScanVerified
            && !hasCurrentProEntitlement
            && statusSnapshotVerified
            && !statusSuggestsPro
    }
}

enum ContextualAdvertisingConsent: Equatable, Sendable {
    case unknown
    case declined
    case granted(disclosureVersion: String)
}

enum ContextualAdvertisingEntitlement: Equatable, Sendable {
    case unknown
    case checking
    case loading
    case busy
    case verifiedFree
    case pro
    case unavailable
}

enum ContextualAdvertisingPlacement {
    /// Fixed, coarse context. The API accepts no image, OCR, account or editing arguments.
    static let homePhotoPrivacy = "home.fixed.photo-privacy"
}

enum ContextualAdvertisingLimits {
    static let maximumResponseBytes = 8 * 1024
}

struct ContextualAdvertisingConfiguration: Equatable, Sendable {
    static let supportedDisclosureVersion = "2026-10-v1"
    static let dataDisclosureText = "The ad provider receives your IP address and standard request information to deliver an ad. Veil does not send photos, photo metadata, OCR text, account details, or editing activity."

    let inventoryURL: URL
    let providerPrivacyURL: URL
    let reportURL: URL
    let providerDisplayName: String
    let disclosureVersion: String

    init?(inventoryURL: URL,
          providerPrivacyURL: URL,
          reportURL: URL,
          providerDisplayName: String,
          disclosureVersion: String,
          appPrivacyPublished: Bool,
          supportPublished: Bool) {
        guard appPrivacyPublished, supportPublished,
              Self.isApprovedHTTPSURL(inventoryURL),
              Self.isApprovedHTTPSURL(providerPrivacyURL),
              Self.isApprovedHTTPSURL(reportURL),
              (1...80).contains(providerDisplayName.utf8.count),
              providerDisplayName == providerDisplayName.trimmingCharacters(in: .whitespacesAndNewlines),
              providerDisplayName.unicodeScalars.allSatisfy({
                  !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format
              }),
              disclosureVersion == Self.supportedDisclosureVersion,
              disclosureVersion == disclosureVersion.trimmingCharacters(in: .whitespacesAndNewlines),
              disclosureVersion.unicodeScalars.allSatisfy({
                  !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format
              }) else { return nil }
        self.inventoryURL = inventoryURL
        self.providerPrivacyURL = providerPrivacyURL
        self.reportURL = reportURL
        self.providerDisplayName = providerDisplayName
        self.disclosureVersion = disclosureVersion
    }

    static func isApprovedHTTPSURL(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(), host.contains("."),
              !host.hasSuffix("."),
              !Self.isNumericAddress(host), !host.contains(":"),
              components.port == nil || components.port == 443,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              !host.hasSuffix(".local"), !host.hasSuffix(".localhost"), !host.hasSuffix(".internal"),
              !host.hasSuffix(".home.arpa"), host != "home.arpa",
              !host.hasSuffix(".test"), !host.hasSuffix(".invalid"), !host.hasSuffix(".onion"),
              !host.hasSuffix(".example"), !host.hasSuffix(".example.com"), !host.hasSuffix(".example.net"),
              !host.hasSuffix(".example.org"), host != "example.com", host != "example.net", host != "example.org",
              host != "localhost", !host.hasPrefix("localhost.") else { return false }
        return true
    }

    private static func isNumericAddress(_ host: String) -> Bool {
        var ipv4 = in_addr()
        if host.withCString({ inet_pton(AF_INET, $0, &ipv4) }) == 1 { return true }
        var ipv6 = in6_addr()
        if host.withCString({ inet_pton(AF_INET6, $0, &ipv6) }) == 1 { return true }

        // Browsers and URL stacks can interpret short, octal and hexadecimal IPv4 forms.
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard !labels.isEmpty else { return false }
        return labels.allSatisfy { label in
            let value = label.lowercased()
            if value.hasPrefix("0x") {
                return value.count > 2 && value.dropFirst(2).allSatisfy(\.isHexDigit)
            }
            return !value.isEmpty && value.allSatisfy(\.isNumber)
        }
    }

    static func hasSameHTTPSOrigin(_ lhs: URL, _ rhs: URL) -> Bool {
        guard isApprovedHTTPSURL(lhs), isApprovedHTTPSURL(rhs),
              let left = URLComponents(url: lhs, resolvingAgainstBaseURL: false),
              let right = URLComponents(url: rhs, resolvingAgainstBaseURL: false) else { return false }
        return left.host?.lowercased() == right.host?.lowercased()
            && (left.port ?? 443) == (right.port ?? 443)
    }
}

struct ContextualAdvertisingCreative: Equatable, Sendable {
    let advertiser: String
    let headline: String
    let callToAction: String
    let destinationURL: URL
    let reportURL: URL
    let privacyURL: URL
}

@MainActor
protocol ContextualAdvertisingProviding {
    func loadCreative(using configuration: ContextualAdvertisingConfiguration) async throws -> ContextualAdvertisingCreative?
}

/// No provider is installed by default. This adapter is safe to use when a UI owner wants an
/// explicit disabled dependency while inventory, privacy and support readiness are pending.
@MainActor
struct DisabledContextualAdvertisingProvider: ContextualAdvertisingProviding {
    func loadCreative(using configuration: ContextualAdvertisingConfiguration) async throws -> ContextualAdvertisingCreative? { nil }
}

@MainActor
final class ContextualAdvertisingController: ObservableObject {
    @Published private(set) var creative: ContextualAdvertisingCreative?

    private var configuration: ContextualAdvertisingConfiguration?
    private var provider: (any ContextualAdvertisingProviding)?
    private(set) var consent: ContextualAdvertisingConsent = .unknown
    private(set) var entitlement: ContextualAdvertisingEntitlement = .unknown
    private var homeVisible = false
    private var sceneActive = false
    private var generation = UUID()
    private(set) var requestTask: Task<Void, Never>?

    init(configuration: ContextualAdvertisingConfiguration? = nil,
         provider: (any ContextualAdvertisingProviding)? = nil) {
        self.configuration = configuration
        self.provider = provider
    }

    deinit {
        requestTask?.cancel()
    }

    func setConfiguration(_ configuration: ContextualAdvertisingConfiguration?,
                          provider: (any ContextualAdvertisingProviding)?) {
        self.configuration = configuration
        self.provider = provider
        invalidateAndRefresh()
    }

    func setConsent(_ consent: ContextualAdvertisingConsent) {
        guard self.consent != consent else { return }
        self.consent = consent
        invalidateAndRefresh()
    }

    func setEntitlement(_ entitlement: ContextualAdvertisingEntitlement) {
        guard self.entitlement != entitlement else { return }
        self.entitlement = entitlement
        invalidateAndRefresh()
    }

    func setHomeVisible(_ visible: Bool) {
        guard homeVisible != visible else { return }
        homeVisible = visible
        invalidateAndRefresh()
    }

    func setSceneActive(_ active: Bool) {
        guard sceneActive != active else { return }
        sceneActive = active
        invalidateAndRefresh()
    }

    private var eligible: Bool {
        guard let configuration,
              case .granted(let version) = consent,
              version == configuration.disclosureVersion,
              entitlement == .verifiedFree,
              homeVisible, sceneActive else { return false }
        return true
    }

    private func invalidateAndRefresh() {
        generation = UUID()
        requestTask?.cancel()
        requestTask = nil
        creative = nil
        guard eligible, let configuration, let provider else { return }

        let requestGeneration = generation
        requestTask = Task { [weak self] in
            do {
                let result = try await provider.loadCreative(using: configuration)
                guard !Task.isCancelled, let self, self.generation == requestGeneration, self.eligible else { return }
                self.creative = result
            } catch {
                // Inventory failures stay quiet: no placeholder or error UI is shown.
                guard !Task.isCancelled, let self, self.generation == requestGeneration else { return }
                self.creative = nil
            }
        }
    }
}

/// Optional first-party JSON transport. It sends no device, account, photo or session data.
@MainActor
final class URLSessionContextualAdvertisingProvider: NSObject, ContextualAdvertisingProviding {
    private let redirectDelegate = SameOriginRedirectDelegate()
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.waitsForConnectivity = false
        configuration.httpMaximumConnectionsPerHost = 1
        return URLSession(configuration: configuration, delegate: redirectDelegate, delegateQueue: nil)
    }()

    func loadCreative(using configuration: ContextualAdvertisingConfiguration) async throws -> ContextualAdvertisingCreative? {
        guard ContextualAdvertisingConfiguration.isApprovedHTTPSURL(configuration.inventoryURL) else { return nil }
        var request = URLRequest(url: configuration.inventoryURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse,
              (200...299).contains(response.statusCode),
              response.mimeType?.lowercased() == "application/json",
              (response.expectedContentLength < 0 || response.expectedContentLength <= Int64(ContextualAdvertisingLimits.maximumResponseBytes)),
              let finalURL = response.url,
              ContextualAdvertisingConfiguration.hasSameHTTPSOrigin(finalURL, configuration.inventoryURL) else { return nil }

        var data = Data()
        for try await byte in bytes {
            guard data.count < ContextualAdvertisingLimits.maximumResponseBytes else { return nil }
            data.append(byte)
        }
        return ContextualAdvertisingCreative.decode(data, configuration: configuration)
    }

}

private final class SameOriginRedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard let originalURL = task.originalRequest?.url,
              let redirectedURL = request.url,
              ContextualAdvertisingConfiguration.hasSameHTTPSOrigin(redirectedURL, originalURL) else {
            completionHandler(nil)
            return
        }
        completionHandler(request)
    }

}

extension ContextualAdvertisingCreative {
    static func decode(_ data: Data, configuration: ContextualAdvertisingConfiguration) -> ContextualAdvertisingCreative? {
        guard data.count <= ContextualAdvertisingLimits.maximumResponseBytes,
              let object = try? JSONSerialization.jsonObject(with: data),
              let fields = object as? [String: Any],
              Set(fields.keys) == Set(["advertiser", "headline", "callToAction", "destinationURL", "reportURL"]) else { return nil }

        func boundedText(_ key: String, maximum: Int) -> String? {
            if let number = fields[key] as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() { return nil }
            guard let value = fields[key] as? String,
                  (1...maximum).contains(value.utf8.count),
                  value == value.trimmingCharacters(in: .whitespacesAndNewlines),
                  value.unicodeScalars.allSatisfy({
                      !CharacterSet.controlCharacters.contains($0) && $0.properties.generalCategory != .format
                  }) else { return nil }
            return value
        }
        guard let advertiser = boundedText("advertiser", maximum: 80),
              let headline = boundedText("headline", maximum: 120),
              let callToAction = boundedText("callToAction", maximum: 32),
              let destinationText = boundedText("destinationURL", maximum: 512),
              let reportText = boundedText("reportURL", maximum: 512),
              let destinationURL = URL(string: destinationText),
              let reportURL = URL(string: reportText),
              ContextualAdvertisingConfiguration.isApprovedHTTPSURL(destinationURL),
              ContextualAdvertisingConfiguration.isApprovedHTTPSURL(reportURL),
              reportURL == configuration.reportURL else { return nil }

        return ContextualAdvertisingCreative(advertiser: advertiser, headline: headline,
            callToAction: callToAction, destinationURL: destinationURL,
            reportURL: reportURL, privacyURL: configuration.providerPrivacyURL)
    }
}
