import Foundation
import Security

struct APIKeyManager: Sendable {
    private static let keychainService = "com.respiro.desktop"
    private static let keychainAccount = "anthropic_api_key"
    private static let legacyDefaultsKey = "anthropic_api_key"

    /// Returns API key from best available source
    static func getAPIKey() -> String? {
        // 1. Environment variable (for development)
        if let envKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        // 2. Info.plist (for distribution)
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String, !plistKey.isEmpty {
            return plistKey
        }
        // 3. Migrate from UserDefaults to Keychain if needed
        migrateFromUserDefaultsIfNeeded()
        // 4. Keychain (for user-entered key in Settings)
        if let savedKey = readFromKeychain(), !savedKey.isEmpty {
            return savedKey
        }
        return nil
    }

    /// Save user-provided key to Keychain
    static func saveAPIKey(_ key: String) {
        saveToKeychain(key)
    }

    /// Check if key is available
    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    // MARK: - Keychain Helpers

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private static func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Migration

    /// Moves API key from UserDefaults (plaintext) to Keychain, then removes from UserDefaults
    private static func migrateFromUserDefaultsIfNeeded() {
        guard let legacyKey = UserDefaults.standard.string(forKey: legacyDefaultsKey), !legacyKey.isEmpty else {
            return
        }
        // Only migrate if Keychain doesn't already have a value
        if readFromKeychain() == nil {
            saveToKeychain(legacyKey)
        }
        // Always clean up plaintext storage
        UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
    }
}
