import Foundation

struct DaySummaryResponse: Codable, Sendable {
    let overallMood: String
    let stressPattern: String
    let effectivePractice: String
    let recommendation: String
    let dayScore: Int
    var thinkingText: String?

    enum CodingKeys: String, CodingKey {
        case overallMood = "overall_mood"
        case stressPattern = "stress_pattern"
        case effectivePractice = "effective_practice"
        case recommendation
        case dayScore = "day_score"
        // thinkingText is NOT in CodingKeys — set programmatically from thinking blocks
    }
}
