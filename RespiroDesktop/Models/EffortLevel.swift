import Foundation

enum EffortLevel: String, Codable, Sendable {
    case low
    case high
    case max

    var budgetTokens: Int {
        switch self {
        case .low:  return 1024
        case .high: return 4096
        case .max:  return 10240
        }
    }

    var maxResponseTokens: Int {
        switch self {
        case .low:  return 1024
        case .high: return 2048
        case .max:  return 4096
        }
    }

    var displayName: String {
        switch self {
        case .low:  return "Quick check"
        case .high: return "Deep reasoning"
        case .max:  return "Full analysis"
        }
    }

    /// Determine effort level based on recent context
    static func determine(recentWeathers: [String], dismissalCount: Int) -> EffortLevel {
        // Any stormy or dismissals → deep reasoning needed
        if recentWeathers.contains("stormy") || dismissalCount > 0 {
            return .high
        }
        // All clear 3+ consecutive → minimal effort
        if recentWeathers.count >= 3 && recentWeathers.prefix(3).allSatisfy({ $0 == "clear" }) {
            return .low
        }
        return .low
    }
}
