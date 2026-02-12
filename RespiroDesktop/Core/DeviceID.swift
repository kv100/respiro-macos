import Foundation
import Security

enum DeviceID: Sendable {
    private static let keychainKey = "respiro_device_id"

    static var current: String {
        if let stored = getFromKeychain() {
            return stored
        }
        let newID = UUID().uuidString
        saveToKeychain(newID)
        return newID
    }

    private static func getFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.respiro.desktop",
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)

        // First delete any existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.respiro.desktop",
            kSecAttrAccount as String: keychainKey
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item with accessibility flag to avoid password prompts
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.respiro.desktop",
            kSecAttrAccount as String: keychainKey,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }
}
