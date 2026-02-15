import Foundation

struct SilenceDecision: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let reason: String
    let thinkingText: String
    let effortLevel: EffortLevel
    let detectedWeather: InnerWeather
    let signals: [String]
    let flowDuration: TimeInterval?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        reason: String,
        thinkingText: String,
        effortLevel: EffortLevel,
        detectedWeather: InnerWeather,
        signals: [String],
        flowDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.reason = reason
        self.thinkingText = thinkingText
        self.effortLevel = effortLevel
        self.detectedWeather = detectedWeather
        self.signals = signals
        self.flowDuration = flowDuration
    }

    /// Human-readable summary of the reason for silence
    var reasonSummary: String {
        let base = reason
            .replacingOccurrences(of: #"\s*\[.*?\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "[]")))
        switch base {
        case "ai_no_nudge": return "Everything looks fine — no need to interrupt"
        case "behavioral_contradiction": return "Behavior doesn't match — staying quiet"
        case "hard_min_interval": return "Too soon since last check"
        case "min_nudge_interval": return "Cooldown active between nudges"
        case "min_practice_interval": return "Cooldown active between practices"
        case "post_practice_cooldown": return "Resting after recent practice"
        case "daily_total_limit": return "Daily nudge limit reached"
        case "daily_practice_limit": return "Daily practice limit reached"
        case "false_positive_suppressed": return "Similar context was dismissed before"
        case "smart_suppression_video_call": return "You're on a video call"
        case "smart_suppression_screen_sharing": return "Screen sharing detected"
        default:
            if base.hasPrefix("suppressed_") {
                return "Suppressed: \(base.dropFirst(11).replacingOccurrences(of: "_", with: " "))"
            }
            if base.hasPrefix("delayed_") {
                return "Delayed: \(base.dropFirst(8).replacingOccurrences(of: "_", with: " "))"
            }
            return base.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
