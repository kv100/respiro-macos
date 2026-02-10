import Foundation

struct StressAnalysisResponse: Codable, Sendable {
    let weather: String
    let confidence: Double
    let signals: [String]
    let nudgeType: String?
    let nudgeMessage: String?
    let suggestedPracticeID: String?

    enum CodingKeys: String, CodingKey {
        case weather, confidence, signals
        case nudgeType = "nudge_type"
        case nudgeMessage = "nudge_message"
        case suggestedPracticeID = "suggested_practice_id"
    }
}
