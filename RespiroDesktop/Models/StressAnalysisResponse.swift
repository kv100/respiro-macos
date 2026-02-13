import Foundation

// MARK: - Tool Use Types

/// Context passed to ClaudeVisionClient for tool use responses.
/// Pre-fetched by caller since ClaudeVisionClient is a Sendable struct
/// and cannot access SwiftData directly.
struct ToolContext: Sendable {
    /// JSON string of recent PracticeSession data (id, practiceID, weatherBefore, weatherAfter, wasCompleted, date)
    let practiceHistory: String
    /// JSON string of recent StressEntry data (weather, confidence, signals, timestamp)
    let weatherHistory: String
    /// Practice IDs the user has completed and rated positively
    let preferredPractices: [String]
}

/// Record of a single tool call made by Claude during analysis.
/// Used for demo display to showcase interleaved thinking between tool calls.
struct ToolCall: Codable, Sendable {
    let name: String
    /// JSON string of the tool input parameters
    let input: String
}

// MARK: - Stress Analysis Response

struct StressAnalysisResponse: Codable, Sendable {
    let weather: String
    let confidence: Double
    let signals: [String]
    let nudgeType: String?
    let nudgeMessage: String?
    let suggestedPracticeID: String?

    /// AI's internal reasoning (extracted from thinking blocks, not from JSON)
    var thinkingText: String?
    /// Effort level used for this analysis (set after parsing, not from JSON)
    var effortLevel: EffortLevel?
    /// Log of tool calls made during analysis (for demo display)
    var toolUseLog: [ToolCall]?
    /// Reason from suggest_practice tool call (user-friendly explanation)
    var practiceReason: String?
    /// Behavioral metrics at time of analysis (set programmatically, not from JSON)
    var behaviorMetrics: BehaviorMetrics?
    /// Baseline deviation at time of analysis (set programmatically, not from JSON)
    var baselineDeviation: Double?
    /// System context at time of analysis (set programmatically, not from JSON)
    var systemContext: SystemContext?

    enum CodingKeys: String, CodingKey {
        case weather, confidence, signals
        case nudgeType = "nudge_type"
        case nudgeMessage = "nudge_message"
        case suggestedPracticeID = "suggested_practice_id"
        // thinkingText, effortLevel, toolUseLog, practiceReason, behaviorMetrics, baselineDeviation, systemContext — set programmatically
    }
}
