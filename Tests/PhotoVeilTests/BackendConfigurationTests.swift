import XCTest
@testable import ImageGeometry

final class BackendConfigurationTests: XCTestCase {
    // Syntactic test data, never bundled in the application or sent to a provider.
    private var fields: [String: Any] {
        ["SupabaseURL": "https://project.example.invalid", "PublishableKey": "sb_publishable_TEST_ONLY_CLIENT_VALUE",
         "RedirectURL": "veil://auth/callback", "AppleCapabilityEnabled": "YES"]
    }
    private func parse(_ fields: [String: Any]) throws -> BackendReadiness {
        BackendConfiguration.parse(try PropertyListSerialization.data(fromPropertyList: fields, format: .xml, options: 0))
    }
    func testMissingAndMalformedConfigurationAreLocalOnly() {
        XCTAssertNil(BackendConfiguration.readiness(bundle: Bundle(for: Self.self)).configuration)
        XCTAssertEqual(BackendConfiguration.parse(Data("not a plist".utf8)), .invalidPropertyList)
    }
    func testConfiguredAppleAndGoogleReadinessIsNotAuthenticationSuccess() throws {
        let ready = try parse(fields)
        XCTAssertNotNil(ready.configuration)
        XCTAssertTrue(try XCTUnwrap(ready.configuration).appleSignInEnabled)
        XCTAssertFalse(ready.diagnostic.contains("TEST_ONLY"))
        var google = fields; google.removeValue(forKey: "AppleCapabilityEnabled")
        XCTAssertFalse(try XCTUnwrap(parse(google).configuration).appleSignInEnabled)
        google["AppleCapabilityEnabled"] = false
        XCTAssertNotNil(try parse(google).configuration)
    }
    func testSessionStorageSeparatesProjectsButNormalizesHostCase() throws {
        let original = try XCTUnwrap(parse(fields).configuration)
        var otherFields = fields; otherFields["SupabaseURL"] = "https://other.example.invalid"
        let other = try XCTUnwrap(parse(otherFields).configuration)
        XCTAssertNotEqual(original.authStorageKey, other.authStorageKey)
        otherFields["SupabaseURL"] = "https://PROJECT.example.invalid/"
        XCTAssertEqual(original.authStorageKey, try XCTUnwrap(parse(otherFields).configuration).authStorageKey)
        XCTAssertFalse(original.authStorageKey.contains(original.publishableKey))
    }
    func testInvalidFieldsAndSecretKeysNeverCreateClientConfiguration() throws {
        for field in ["SupabaseURL", "PublishableKey", "RedirectURL"] {
            var changed = fields; changed.removeValue(forKey: field)
            XCTAssertEqual(try parse(changed), .invalidField(field))
        }
        for key in ["sb_secret_TEST_ONLY_PRIVATE_VALUE", "eyJ_TEST_ONLY_LEGACY_JWT", "sb_publishable_has whitespace"] {
            var changed = fields; changed["PublishableKey"] = key
            XCTAssertEqual(try parse(changed), .invalidField("PublishableKey"))
        }
        for endpoint in ["http://project.example.invalid", "https://project.example.invalid/path", "https://user@project.example.invalid", "https://project.example.invalid?x=y", "https://project.example.invalid:8443"] {
            var changed = fields; changed["SupabaseURL"] = endpoint
            XCTAssertEqual(try parse(changed), .invalidField("SupabaseURL"))
        }
        for callback in ["other://auth/callback", "veil://other/callback", "veil://auth/callback?code=x", "veil://auth/callback#token", "veil://user@auth/callback", "veil://auth:12/callback"] {
            var changed = fields; changed["RedirectURL"] = callback
            XCTAssertEqual(try parse(changed), .invalidField("RedirectURL"))
        }
        var changed = fields; changed["AppleCapabilityEnabled"] = "maybe"
        XCTAssertEqual(try parse(changed), .invalidField("AppleCapabilityEnabled"))
    }
}
