import Foundation

enum NudgeType: String, Codable, Sendable {
    case practice
    case encouragement
    case acknowledgment

    /// Normalize AI responses that use non-standard nudge type strings
    static func from(_ raw: String?) -> NudgeType? {
        guard let raw else { return nil }
        if let exact = NudgeType(rawValue: raw) { return exact }
        // Claude sometimes returns specific practice types instead of "practice"
        let practiceAliases = ["breathing", "grounding", "mindfulness", "body_scan", "meditation", "relaxation", "cognitive", "visualization", "wellbeing", "wellness", "stretch", "movement", "suggestion", "break", "rest", "pause"]
        if practiceAliases.contains(raw.lowercased()) { return .practice }
        return nil
    }
}
