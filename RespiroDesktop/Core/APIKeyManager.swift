import Foundation

struct APIKeyManager: Sendable {
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
        // 3. UserDefaults (for user-entered key in Settings)
        if let savedKey = UserDefaults.standard.string(forKey: "anthropic_api_key"), !savedKey.isEmpty {
            return savedKey
        }
        return nil
    }

    /// Save user-provided key
    static func saveAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "anthropic_api_key")
    }

    /// Check if key is available
    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }
}
