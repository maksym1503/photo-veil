import Auth
import Foundation
import Security

/// Platform Keychain; device-bound, accessible only while unlocked. No custom cryptography.
struct ProtectedAuthStorage: AuthLocalStorage {
    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.maksym1503.veil.auth",
         kSecAttrAccount as String: key, kSecAttrSynchronizable as String: false]
    }
    func store(key: String, value: Data) throws {
        let attributes: [String: Any] = [kSecValueData as String: value, kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let update = SecItemUpdate(query(key) as CFDictionary, attributes as CFDictionary)
        if update == errSecItemNotFound {
            var insert = query(key); insert.merge(attributes) { _, new in new }
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else { throw AccountFailure.unavailable }
        } else if update != errSecSuccess { throw AccountFailure.unavailable }
    }
    func retrieve(key: String) throws -> Data? {
        var lookup = query(key); lookup[kSecReturnData as String] = true; lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &value)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw AccountFailure.unavailable }
        return value as? Data
    }
    func remove(key: String) throws {
        let status = SecItemDelete(query(key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw AccountFailure.unavailable }
    }
}
