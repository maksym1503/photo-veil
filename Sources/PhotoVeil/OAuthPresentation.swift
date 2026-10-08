import AuthenticationServices
import UIKit

/// The SDK still creates PKCE and exchanges the code. This layer only presents native browser UI
/// and rejects callbacks outside the registered route before handing them to the SDK.
@MainActor private final class OAuthPresentation: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<URL, Error>?
    private let anchor: UIWindow
    init(anchor: UIWindow) { self.anchor = anchor }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
    static func authenticate(_ url: URL, callback: URL) async throws -> URL {
        guard let window = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows).first(where: \.isKeyWindow) else { throw AccountFailure.unavailable }
        let presenter = OAuthPresentation(anchor: window)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                presenter.continuation = continuation
                let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callback.scheme) { result, error in
                    Task { @MainActor in
                        if let error { presenter.finish(.failure(error)) }
                        else if let result, OAuthCallbackPolicy.accepts(result, expected: callback) { presenter.finish(.success(result)) }
                        else { presenter.finish(.failure(AccountFailure.invalidIdentity)) }
                    }
                }
                session.presentationContextProvider = presenter
                session.prefersEphemeralWebBrowserSession = true
                presenter.session = session
                if !session.start() { presenter.finish(.failure(AccountFailure.unavailable)) }
            }
        } onCancel: {
            Task { @MainActor in presenter.session?.cancel(); presenter.finish(.failure(CancellationError())) }
        }
    }
    private func finish(_ result: Result<URL, Error>) {
        let pending = continuation; continuation = nil; session = nil
        pending?.resume(with: result)
    }
}

@MainActor enum GoogleOAuthPresentation {
    static func authenticate(_ url: URL, callback: URL) async throws -> URL {
        try await OAuthPresentation.authenticate(url, callback: callback)
    }
}

@MainActor enum PrivacyShield {
    private static let tag = 0x5645494C
    static func cover(_ covered: Bool) {
        for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap(\.windows) where window.isKeyWindow {
            window.viewWithTag(tag)?.removeFromSuperview()
            guard covered else { continue }
            let shield = UIView(frame: window.bounds); shield.tag = tag; shield.backgroundColor = .systemBackground
            shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            let label = UILabel(); label.text = "Veil"; label.font = .preferredFont(forTextStyle: .title1)
            label.textColor = .label; label.translatesAutoresizingMaskIntoConstraints = false
            shield.addSubview(label)
            NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: shield.centerXAnchor), label.centerYAnchor.constraint(equalTo: shield.centerYAnchor)])
            window.addSubview(shield)
        }
    }
}
