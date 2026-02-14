import Foundation

// TODO: Remove hardcoded fallbacks before production release
enum RespiroConfig {
    static var supabaseURL: String {
        resolve(
            envKey: "SUPABASE_URL",
            plistKey: "SUPABASE_URL",
            fallback: "https://vvodwmlwwpheqtweduew.supabase.co"
        )
    }

    static var supabaseAnonKey: String {
        resolve(
            envKey: "SUPABASE_ANON_KEY",
            plistKey: "SUPABASE_ANON_KEY",
            fallback: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2b2R3bWx3d3BoZXF0d2VkdWV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMzc2NDgsImV4cCI6MjA4MjYxMzY0OH0.GPDDM6ADr8lZeJ76kN_mCIAMXJCQwtIooEYfQuRtiK0"
        )
    }

    static var proxyEndpoint: String {
        "\(supabaseURL)/functions/v1/claude-proxy"
    }

    // Railway proxy for long-running requests (no 150s timeout limit)
    static var railwayProxyURL: String {
        resolve(
            envKey: "RAILWAY_PROXY_URL",
            plistKey: "RAILWAY_PROXY_URL",
            fallback: "https://respiro-proxy-production.up.railway.app"
        )
    }

    // MARK: - Private

    private static func resolve(envKey: String, plistKey: String, fallback: String) -> String {
        if let env = ProcessInfo.processInfo.environment[envKey], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String, !plist.isEmpty {
            return plist
        }
        return fallback
    }
}
