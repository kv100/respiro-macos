import Foundation

// MARK: - Regression Bug

/// A bug found during playtest, saved for regression testing.
/// Instead of saving full scenario data (which becomes stale),
/// we save bug descriptions and regenerate fresh scenarios when running regression.
struct RegressionBug: Codable, Sendable {
    let scenarioID: String
    let scenarioName: String
    let description: String
    let hypothesis: String?
    let mismatches: [String]
    let expectedBehavior: [String]
    let round: Int
}

// MARK: - Scenario Step

struct ScenarioStep: Sendable, Identifiable, Codable {
    let id: String
    let description: String
    let mockAnalysis: StressAnalysisResponse
    let userAction: PlaytestUserAction?
    let timeDelta: TimeInterval

    // NEW: Behavioral context for this step
    let behaviorMetrics: BehaviorMetrics?
    let systemContext: SystemContext?
    let baselineDeviation: Double?

    enum CodingKeys: String, CodingKey {
        case id, description, mockAnalysis, userAction, timeDelta
        case behaviorMetrics, systemContext, baselineDeviation
    }

    init(id: String, description: String, mockAnalysis: StressAnalysisResponse,
         userAction: PlaytestUserAction?, timeDelta: TimeInterval,
         behaviorMetrics: BehaviorMetrics? = nil, systemContext: SystemContext? = nil,
         baselineDeviation: Double? = nil) {
        self.id = id
        self.description = description
        self.mockAnalysis = mockAnalysis
        self.userAction = userAction
        self.timeDelta = timeDelta
        self.behaviorMetrics = behaviorMetrics
        self.systemContext = systemContext
        self.baselineDeviation = baselineDeviation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        description = try container.decode(String.self, forKey: .description)
        mockAnalysis = try container.decode(StressAnalysisResponse.self, forKey: .mockAnalysis)
        userAction = try container.decodeIfPresent(PlaytestUserAction.self, forKey: .userAction)
        timeDelta = try container.decode(TimeInterval.self, forKey: .timeDelta)
        behaviorMetrics = try container.decodeIfPresent(BehaviorMetrics.self, forKey: .behaviorMetrics)
        systemContext = try container.decodeIfPresent(SystemContext.self, forKey: .systemContext)
        baselineDeviation = try container.decodeIfPresent(Double.self, forKey: .baselineDeviation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(description, forKey: .description)
        try container.encode(mockAnalysis, forKey: .mockAnalysis)
        try container.encodeIfPresent(userAction, forKey: .userAction)
        try container.encode(timeDelta, forKey: .timeDelta)
        try container.encodeIfPresent(behaviorMetrics, forKey: .behaviorMetrics)
        try container.encodeIfPresent(systemContext, forKey: .systemContext)
        try container.encodeIfPresent(baselineDeviation, forKey: .baselineDeviation)
    }
}

enum PlaytestUserAction: String, Sendable, Codable {
    case dismissImFine
    case dismissLater
    case startPractice
    case completePractice
}

// MARK: - Scenario

struct PlaytestScenario: Sendable, Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let steps: [ScenarioStep]
    let round: Int
    let expectedBehavior: [String]
    let hypothesis: String?
    let assertions: [PlaytestAssertion]
    var falsePositiveSeeds: [FalsePositiveSeed]?

    struct FalsePositiveSeed: Sendable, Codable {
        let context: String
        let confidence: Double
        let count: Int
    }
}

struct PlaytestAssertion: Sendable, Codable {
    let stepID: String
    let field: AssertionField
    let expected: String

    enum AssertionField: String, Sendable, Codable {
        case nudgeShouldShow
        case nudgeType
        case cooldownActive

        // NEW: Behavioral assertions
        case behavioralContextUsed
        case baselineDeviationConsidered
        case contextSwitchRateCorrect
    }
}

// MARK: - Result

struct PlaytestResult: Sendable {
    let scenarioID: String
    let stepResults: [StepResult]
    let totalDuration: TimeInterval

    struct StepResult: Sendable, Identifiable {
        let id: String
        let nudgeDecision: NudgeDecision
        let cooldownState: CooldownSnapshot
        let timestamp: Date

        // NEW: Store behavioral data from test
        let behaviorMetrics: BehaviorMetrics?
        let baselineDeviation: Double?
    }

    struct CooldownSnapshot: Sendable {
        let consecutiveDismissals: Int
        let dailyNudgeCount: Int
        let dailyPracticeNudgeCount: Int
        let isInCooldown: Bool
        let cooldownReason: String?
    }
}

// MARK: - Evaluation

struct ScenarioEvaluation: Codable, Sendable {
    let scenarioID: String
    let passed: Bool
    let confidence: Double
    let reasoning: String
    let mismatches: [String]
    let suggestions: [String]
    let thinkingText: String?

    // NEW: Behavioral evaluation metrics
    let behavioralReasoningQuality: Double?  // 0-1
    let usedBehavioralContext: Bool

    static func error(scenarioID: String, message: String) -> ScenarioEvaluation {
        ScenarioEvaluation(
            scenarioID: scenarioID, passed: false, confidence: 0,
            reasoning: "Error: \(message)", mismatches: [], suggestions: [],
            thinkingText: nil,
            behavioralReasoningQuality: nil,
            usedBehavioralContext: false
        )
    }
}

// MARK: - Report

struct PlaytestReport: Sendable {
    let rounds: [PlaytestRound]
    let overallPassed: Bool
    let overallConfidence: Double
    let summary: String
    let discoveries: [String]
    let criticalIssues: [String]
    let strengths: [String]
    let untestedAreas: [String]
    let confidenceTrajectory: [Double]
    let thinkingText: String?
    let completedAt: Date
}

struct PlaytestRound: Sendable, Identifiable {
    let id: Int
    let scenarios: [PlaytestScenario]
    let evaluations: [ScenarioEvaluation]
    let isAIGenerated: Bool
}

// MARK: - StressAnalysisResponse Convenience Factories

extension StressAnalysisResponse {
    /// Clear weather mock
    static func clear(confidence: Double, signals: [String]) -> StressAnalysisResponse {
        StressAnalysisResponse(
            weather: "clear",
            confidence: confidence,
            signals: signals,
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
    }

    /// Cloudy weather mock
    static func cloudy(confidence: Double, signals: [String]) -> StressAnalysisResponse {
        StressAnalysisResponse(
            weather: "cloudy",
            confidence: confidence,
            signals: signals,
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
    }

    /// Stormy weather mock with optional nudge
    static func stormy(
        confidence: Double,
        signals: [String],
        nudge: NudgeType? = nil,
        message: String? = nil,
        practiceID: String? = nil
    ) -> StressAnalysisResponse {
        StressAnalysisResponse(
            weather: "stormy",
            confidence: confidence,
            signals: signals,
            nudgeType: nudge?.rawValue,
            nudgeMessage: message,
            suggestedPracticeID: practiceID
        )
    }
}
