import Foundation

enum RespiroConfig {
    static let supabaseURL = "https://vvodwmlwwpheqtweduew.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2b2R3bWx3d3BoZXF0d2VkdWV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjcwMzc2NDgsImV4cCI6MjA4MjYxMzY0OH0.GPDDM6ADr8lZeJ76kN_mCIAMXJCQwtIooEYfQuRtiK0"
    static let proxyEndpoint = "\(supabaseURL)/functions/v1/claude-proxy"

    // Railway proxy for long-running requests (no 150s timeout limit)
    static let railwayProxyURL = "https://respiro-proxy-production.up.railway.app"
}
