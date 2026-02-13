import Foundation

struct ResultEvaluator: Sendable {
    let mode: ClaudeVisionClient.Mode

    private static let model = "claude-opus-4-6"
    private static let apiVersion = "2023-06-01"

    // MARK: - Public API

    func evaluate(
        scenario: PlaytestScenario,
        result: PlaytestResult
    ) async throws -> ScenarioEvaluation {
        let prompt = buildEvaluationPrompt(scenario: scenario, result: result)
        let response = try await callClaude(
            systemPrompt: "You are an AI app behavior evaluator. Analyze test results and respond with JSON only.",
            userPrompt: prompt,
            thinkingBudget: 10000,  // High budget for deep evaluation
            maxTokens: 2048
        )
        return parseEvaluation(response, scenarioID: scenario.id)
    }

    func generateReport(rounds: [PlaytestRound]) async throws -> PlaytestReport {
        let prompt = buildReportPrompt(rounds: rounds)
        let response = try await callClaude(
            systemPrompt: "You are an AI testing analyst. Generate exploration reports in JSON format.",
            userPrompt: prompt,
            thinkingBudget: 10240,
            maxTokens: 4096
        )
        return parseReport(response, rounds: rounds)
    }

    // MARK: - Prompt Building

    private func buildEvaluationPrompt(scenario: PlaytestScenario, result: PlaytestResult) -> String {
        var prompt = """
        You are evaluating a stress-coaching AI app's behavior.
        The app uses weather metaphors (clear/cloudy/stormy) and decides
        when to nudge users with stress-relief practices.

        SCENARIO: \(scenario.name)
        DESCRIPTION: \(scenario.description)

        EXPECTED BEHAVIOR:
        """
        for expected in scenario.expectedBehavior {
            prompt += "\n- \(expected)"
        }

        if let hypothesis = scenario.hypothesis {
            prompt += "\n\nHYPOTHESIS: \(hypothesis)"
        }

        prompt += "\n\nSTEP-BY-STEP TRACE:"
        for (index, stepResult) in result.stepResults.enumerated() {
            let step = scenario.steps[safe: index]
            let stepDesc = step?.description ?? "Step \(stepResult.id)"
            prompt += """
            \n  Step \(stepResult.id) (\(stepDesc)):
              - Nudge shown: \(stepResult.nudgeDecision.shouldShow)
              - Nudge type: \(stepResult.nudgeDecision.nudgeType?.rawValue ?? "none")
              - Reason: \(stepResult.nudgeDecision.reason)
              - Cooldown active: \(stepResult.cooldownState.isInCooldown)
              - Cooldown reason: \(stepResult.cooldownState.cooldownReason ?? "none")
              - Consecutive dismissals: \(stepResult.cooldownState.consecutiveDismissals)
              - Daily nudge count: \(stepResult.cooldownState.dailyNudgeCount)
            """

            // Add behavioral context if present
            if let behaviorMetrics = stepResult.behaviorMetrics,
               let baselineDeviation = stepResult.baselineDeviation {
                prompt += """
                \n    Behavioral context:
                  - Context switches/min: \(String(format: "%.1f", behaviorMetrics.contextSwitchesPerMinute))
                  - Baseline deviation: \(String(format: "%.0f%%", baselineDeviation * 100))
                  - Session duration: \(Int(behaviorMetrics.sessionDuration))s
                  - Recent app switches: \(behaviorMetrics.recentAppSequence.joined(separator: " → "))
                """
            }
        }

        prompt += """


        Analyze whether the app's behavior is correct. Consider:
        1. Did the nudge logic match expectations?
        2. Were cooldowns applied correctly?
        3. Would this behavior feel natural to a user?
        4. Are there edge cases or subtle bugs?

        BEHAVIORAL ANALYSIS EVALUATION:

        For steps with behavioral context (behaviorMetrics, baselineDeviation):

        1. CHECK BEHAVIORAL REASONING:
           - Did AI mention context switches in reasoning?
           - Did AI consider baseline deviation?
           - Did AI reference behavioral patterns (session duration, app focus)?

        2. ASSESS QUALITY (0-1 score):
           - 1.0 = Excellent behavioral reasoning (mentioned all relevant factors)
           - 0.7 = Good (mentioned some behavioral factors)
           - 0.4 = Weak (barely mentioned behavior)
           - 0.0 = Ignored behavioral context entirely

        3. IDENTIFY MISMATCHES:
           - High baseline deviation (>150%) but AI didn't mention it
           - High context switches (>5/min) but AI didn't reference it
           - Fragmented app focus but AI said "focused work"

        BEHAVIORAL EVALUATION OUTPUT:
        Return these additional fields:
        - usedBehavioralContext: bool (true if ANY behavioral factor mentioned)
        - behavioralReasoningQuality: 0-1 (how well AI used behavioral data)

        Example:
        Step has: 6.5 switches/min, 280% baseline deviation
        AI reasoning: "High context switching indicates stress. User's activity is 280% above their normal baseline."
        → usedBehavioralContext: true
        → behavioralReasoningQuality: 1.0

        Step has: 6.5 switches/min, 280% baseline deviation
        AI reasoning: "Many tabs and notifications suggest stress."
        → usedBehavioralContext: false
        → behavioralReasoningQuality: 0.0

        Respond with JSON ONLY (no markdown, no code blocks):
        {
          "passed": true/false,
          "confidence": 0.0-1.0,
          "reasoning": "plain English analysis",
          "mismatches": ["specific difference 1", ...],
          "suggestions": ["improvement idea 1", ...],
          "usedBehavioralContext": true/false,
          "behavioralReasoningQuality": 0.0-1.0
        }
        """
        return prompt
    }

    private func buildReportPrompt(rounds: [PlaytestRound]) -> String {
        let totalScenarios = rounds.flatMap(\.scenarios).count

        var prompt = """
        You explored a stress-coaching AI app's behavior across \(rounds.count) rounds and \(totalScenarios) total scenarios.

        COMPLETE RESULTS:
        """

        for round in rounds {
            prompt += "\n\nROUND \(round.id) (\(round.isAIGenerated ? "AI-Generated" : "Seed")):"
            for eval in round.evaluations {
                let scenario = round.scenarios.first { $0.id == eval.scenarioID }
                prompt += """
                \n  \(eval.scenarioID) "\(scenario?.name ?? "Unknown")": \(eval.passed ? "PASSED" : "FAILED") (\(Int(eval.confidence * 100))%)
                  Reasoning: \(eval.reasoning)
                """
                if !eval.mismatches.isEmpty {
                    prompt += "\n  Mismatches: \(eval.mismatches.joined(separator: "; "))"
                }
            }
        }

        prompt += """


        Write an exploration report:
        1. Overall app quality assessment
        2. What the exploration discovered (edge cases, boundaries)
        3. Seed scenarios vs AI-generated: which found more issues?
        4. Confidence trajectory across rounds
        5. Remaining untested areas

        Respond with JSON ONLY (no markdown, no code blocks):
        {
          "overall_passed": true/false,
          "overall_confidence": 0.0-1.0,
          "summary": "3-4 sentence assessment",
          "discoveries": ["discovery 1", ...],
          "critical_issues": ["issue 1", ...],
          "strengths": ["strength 1", ...],
          "untested_areas": ["area 1", ...],
          "confidence_trajectory": [round1_conf, round2_conf, ...]
        }
        """
        return prompt
    }

    // MARK: - HTTP

    private var endpoint: URL {
        switch mode {
        case .direct:
            return URL(string: "https://api.anthropic.com/v1/messages")!
        case .proxy:
            // Use Railway proxy — no 150s timeout limit (vs Supabase edge functions)
            return URL(string: RespiroConfig.railwayProxyURL)!
        }
    }

    private func authHeaders() -> [String: String] {
        switch mode {
        case .direct(let apiKey):
            return [
                "x-api-key": apiKey,
                "anthropic-version": Self.apiVersion,
            ]
        case .proxy(_, _, let deviceID):
            // Railway proxy handles Anthropic auth server-side
            return ["x-device-id": deviceID]
        }
    }

    private func callClaude(
        systemPrompt: String,
        userPrompt: String,
        thinkingBudget: Int,
        maxTokens: Int
    ) async throws -> (text: String, thinking: String?) {
        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": thinkingBudget + maxTokens,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userPrompt]],
            "thinking": ["type": "enabled", "budget_tokens": thinkingBudget]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 300  // 5 min — Railway proxy has no 150s limit
        for (key, value) in authHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeAPIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse(statusCode: 0, body: "Not an HTTP response")
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 429:
            throw ClaudeAPIError.rateLimited
        case 500...599:
            throw ClaudeAPIError.serverError(statusCode: httpResponse.statusCode)
        default:
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing content: \(body)")
        }

        var thinkingParts: [String] = []
        var textContent: String?

        for block in content {
            guard let blockType = block["type"] as? String else { continue }
            switch blockType {
            case "thinking":
                if let thinking = block["thinking"] as? String, !thinking.isEmpty {
                    thinkingParts.append(thinking)
                }
            case "text":
                if let text = block["text"] as? String {
                    textContent = text
                }
            default:
                break
            }
        }

        guard let text = textContent else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing text content: \(body)")
        }

        let thinking = thinkingParts.isEmpty ? nil : thinkingParts.joined(separator: "\n\n")
        return (text: text, thinking: thinking)
    }

    // MARK: - Parsing

    private func parseEvaluation(_ response: (text: String, thinking: String?), scenarioID: String) -> ScenarioEvaluation {
        let jsonString = extractJSON(from: response.text)
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return .error(scenarioID: scenarioID, message: "Failed to parse evaluation JSON")
        }

        let passed = json["passed"] as? Bool ?? false
        let confidence = json["confidence"] as? Double ?? 0
        let reasoning = json["reasoning"] as? String ?? "No reasoning provided"
        let mismatches = json["mismatches"] as? [String] ?? []
        let suggestions = json["suggestions"] as? [String] ?? []

        // Parse behavioral evaluation fields
        let usedBehavioralContext = json["usedBehavioralContext"] as? Bool ?? false
        let behavioralReasoningQuality = json["behavioralReasoningQuality"] as? Double

        return ScenarioEvaluation(
            scenarioID: scenarioID,
            passed: passed,
            confidence: confidence,
            reasoning: reasoning,
            mismatches: mismatches,
            suggestions: suggestions,
            thinkingText: response.thinking,
            behavioralReasoningQuality: behavioralReasoningQuality,
            usedBehavioralContext: usedBehavioralContext
        )
    }

    private func parseReport(_ response: (text: String, thinking: String?), rounds: [PlaytestRound]) -> PlaytestReport {
        let jsonString = extractJSON(from: response.text)

        var overallPassed = true
        var overallConfidence = 0.0
        var summary = "Report generation completed."
        var discoveries: [String] = []
        var criticalIssues: [String] = []
        var strengths: [String] = []
        var untestedAreas: [String] = []
        var confidenceTrajectory: [Double] = []

        if let jsonData = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            overallPassed = json["overall_passed"] as? Bool ?? true
            overallConfidence = json["overall_confidence"] as? Double ?? 0
            summary = json["summary"] as? String ?? summary
            discoveries = json["discoveries"] as? [String] ?? []
            criticalIssues = json["critical_issues"] as? [String] ?? []
            strengths = json["strengths"] as? [String] ?? []
            untestedAreas = json["untested_areas"] as? [String] ?? []
            confidenceTrajectory = json["confidence_trajectory"] as? [Double] ?? []
        }

        return PlaytestReport(
            rounds: rounds,
            overallPassed: overallPassed,
            overallConfidence: overallConfidence,
            summary: summary,
            discoveries: discoveries,
            criticalIssues: criticalIssues,
            strengths: strengths,
            untestedAreas: untestedAreas,
            confidenceTrajectory: confidenceTrajectory,
            thinkingText: response.thinking,
            completedAt: Date()
        )
    }

    // MARK: - JSON Extraction

    private func extractJSON(from text: String) -> String {
        if let range = text.range(of: "```json"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = text.range(of: "```"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
