import Foundation

struct ScenarioGenerator: Sendable {
    let mode: ClaudeVisionClient.Mode

    private static let model = "claude-opus-4-6"
    private static let apiVersion = "2023-06-01"

    func generateNext(
        previousRounds: [PlaytestRound],
        roundNumber: Int
    ) async throws -> [PlaytestScenario] {
        let prompt = buildGenerationPrompt(previousRounds: previousRounds)
        let response = try await callClaude(
            systemPrompt: "You are an AI testing specialist. Generate new test scenarios as JSON.",
            userPrompt: prompt,
            thinkingBudget: 12000,
            maxTokens: 16384
        )
        let generated = parseGeneratedScenarios(response.text, roundNumber: roundNumber)
        return generated.filter { isValid($0) }
    }

    // MARK: - Regression Generation

    func generateRegressionScenarios(bugs: [RegressionBug]) async throws -> [PlaytestScenario] {
        // Split into batches of 4 to avoid proxy timeouts
        let batchSize = 4
        var allScenarios: [PlaytestScenario] = []

        for batchStart in stride(from: 0, to: bugs.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, bugs.count)
            let batch = Array(bugs[batchStart..<batchEnd])
            print("[ScenarioGenerator] Generating regression batch \(batchStart/batchSize + 1) (\(batch.count) bugs)...")

            let prompt = buildRegressionPrompt(bugs: batch)
            let response = try await callClaude(
                systemPrompt: "You are an AI testing specialist. Generate regression test scenarios to verify bug fixes. Respond with JSON only.",
                userPrompt: prompt,
                thinkingBudget: 8000,
                maxTokens: 8192
            )
            let scenarios = parseGeneratedScenarios(response.text, roundNumber: 0)
                .filter { isValid($0) }
            allScenarios.append(contentsOf: scenarios)
        }

        return allScenarios
    }

    private func buildRegressionPrompt(bugs: [RegressionBug]) -> String {
        var prompt = """
        You are verifying bug fixes in a stress-coaching app called Respiro.
        The app uses weather metaphors (clear/cloudy/stormy) and decides when to nudge users with practices.

        APP RULES:
        - minPracticeInterval: 30 min between practice nudges
        - minAnyNudgeInterval: 10 min between any nudge
        - hardMinInterval: 5 min absolute minimum
        - postDismissalCooldown: 15 min after dismiss_im_fine
        - consecutiveDismissalCooldown: 2 hours (after 3 dismiss_im_fine — dismiss_later does NOT count)
        - postPracticeCooldown: 45 min
        - maxDailyPracticeNudges: 6
        - maxDailyTotalNudges: 12
        - Confidence >= 0.6 required for practice nudge
        - Smart suppression: skip nudge during video calls AND screen sharing (isOnVideoCall or isScreenSharing)
        - Weather types: clear, cloudy, stormy
        - Nudge types: practice, encouragement, acknowledgment
        - Behavioral override: severity >= 0.7 + confidence >= 0.6 → practice nudge
        - Behavioral encouragement: severity 0.4-0.7 → encouragement nudge (lighter, 10min interval)
        - dismiss_later: updates lastDismissalTime but does NOT increment consecutiveDismissals counter
        - dismiss_im_fine: updates lastDismissalTime AND increments consecutiveDismissals counter

        BEHAVIORAL SEVERITY CALCULATION:
        - switches > 8: +0.4, > 5: +0.3, > 3: +0.15
        - baselineDeviation > 2.5: +0.4, > 1.5: +0.3, > 0.5: +0.15
        - sessionDuration > 3h: +0.1, > 2h: +0.05
        - maxFocus < 0.3: +0.1

        BUGS TO VERIFY (generate one scenario per bug):
        """

        for (index, bug) in bugs.enumerated() {
            prompt += """

            BUG \(index + 1): \(bug.scenarioName)
            Description: \(bug.description)
            \(bug.hypothesis.map { "Hypothesis: \($0)" } ?? "")
            Previous mismatches: \(bug.mismatches.joined(separator: "; "))
            Expected behavior: \(bug.expectedBehavior.joined(separator: "; "))
            """
        }

        prompt += """


        For EACH bug above, generate exactly ONE scenario that directly tests whether the bug is fixed.

        CRITICAL REQUIREMENTS:
        - Include complete behavioral data (behaviorMetrics, systemContext, baselineDeviation) in every step
        - For screen sharing tests: set "is_screen_sharing": true in system_context
        - For dismiss_later tests: use "dismiss_later" as user_action
        - For encouragement tests: ensure behavioral metrics produce severity 0.4-0.7 (e.g., switches > 5, baseline > 1.5)
        - Use realistic, sufficient time_delta between steps (>1801 for practice intervals, >901 for dismissal cooldowns)
        - Each scenario must have clear expected_behavior and a hypothesis explaining what it verifies

        Start scenario IDs from "reg-1".

        For each step, the weather field determines what the mock analysis will contain:
        - "clear" -> no nudge (nudge_type null)
        - "cloudy" -> usually no nudge unless confidence is high
        - "stormy" -> can have nudge_type "practice" or "encouragement" with appropriate message and practice_id

        IMPORTANT: Include behavioral data in steps to test behavioral stress detection:
        - behaviorMetrics: {contextSwitchesPerMinute (double), sessionDuration (seconds), applicationFocus (0.0-1.0), notificationAccumulation (int), recentAppSequence (array of strings)}
        - systemContext: {activeApp (string), openWindowCount (int), isOnVideoCall (bool), isScreenSharing (bool), batteryLevel (double), timeOfDay (string)}
        - baselineDeviation (double, e.g., 0.0 = no change, 2.5 = 250% above baseline)

        Respond with JSON ONLY (no markdown, no code blocks):
        {
          "scenarios": [
            {
              "id": "reg-N",
              "name": "short name",
              "hypothesis": "What this regression test verifies",
              "description": "What the original bug was",
              "steps": [
                {
                  "id": "Na",
                  "description": "step description",
                  "weather": "clear|cloudy|stormy",
                  "confidence": 0.0-1.0,
                  "signals": ["signal1", "signal2"],
                  "nudge_type": "practice|encouragement|null",
                  "nudge_message": "message or null",
                  "practice_id": "id or null",
                  "user_action": "dismiss_im_fine|dismiss_later|start_practice|complete_practice|null",
                  "time_delta": seconds_since_last_step,
                  "behavior_metrics": {
                    "context_switches_per_minute": 0.0,
                    "session_duration": 0,
                    "application_focus": 0.0,
                    "notification_accumulation": 0,
                    "recent_app_sequence": []
                  },
                  "system_context": {
                    "active_app": "AppName",
                    "open_window_count": 0,
                    "is_on_video_call": false,
                    "is_screen_sharing": false,
                    "battery_level": 0.0,
                    "time_of_day": "morning|afternoon|evening"
                  },
                  "baseline_deviation": 0.0
                }
              ],
              "expected_behavior": [...]
            }
          ]
        }
        """
        return prompt
    }

    // MARK: - Prompt Building

    private func buildGenerationPrompt(previousRounds: [PlaytestRound]) -> String {
        var prompt = """
        You are an AI testing specialist analyzing a stress-coaching app called Respiro.
        The app monitors user stress via weather metaphors and decides when to nudge with practices.

        APP RULES:
        - minPracticeInterval: 30 min between practice nudges
        - minAnyNudgeInterval: 10 min between any nudge
        - hardMinInterval: 5 min absolute minimum
        - postDismissalCooldown: 15 min
        - consecutiveDismissalCooldown: 2 hours (after 3 dismissals)
        - postPracticeCooldown: 45 min
        - maxDailyPracticeNudges: 6
        - maxDailyTotalNudges: 12
        - Confidence >= 0.6 required for practice nudge
        - Smart suppression: skip nudge during video calls, presentations
        - Weather types: clear, cloudy, stormy
        - Nudge types: practice, encouragement, acknowledgment
        - Available user actions: dismiss_im_fine, dismiss_later, start_practice, complete_practice

        GENERATE TEST SCENARIOS WITH BEHAVIORAL VARIATIONS:

        Your goal: Create scenarios that test behavioral stress detection edge cases.

        SCENARIO TYPES TO GENERATE:

        1. CONTRASTIVE PAIRS (high priority):
           Same mockAnalysis (visual) but different behaviorMetrics
           - Pair A: Visual chaos + calm behavior (low switches, focused)
           - Pair B: Visual chaos + frantic behavior (high switches, fragmented)
           Test: Does AI differentiate based on behavior alone?

        2. BASELINE EDGE CASES:
           - Normal visual + HUGE baseline spike (300%+)
           - Chaotic visual + baseline match (0-10% deviation)
           Test: Does AI correctly weight baseline deviation?

        3. FALSE POSITIVE PATTERNS:
           - Code review scenario (GitHub PR, terminal errors) but learned FP
           - Friday afternoon (looks busy but user always dismisses)
           - Morning ramp-up (many apps opening but normal pattern)
           Test: Does AI learn from dismissal history?

        4. BEHAVIORAL VELOCITY TESTS:
           - Context switches: test 0.5/min vs 5/min vs 10/min thresholds
           - Session duration: test 30min vs 2h vs 4h without break
           - App focus: test 90% focused vs 30% fragmented
           Test: Does AI detect behavioral stress signals?

        5. PROGRESSIVE DETERIORATION:
           - 3-step scenario: behavior worsens each step
           - Step 1: 2 switches/min, 60min session
           - Step 2: 4 switches/min, 120min session
           - Step 3: 8 switches/min, 180min session
           Test: Does AI detect escalation?

        FOR EACH GENERATED SCENARIO:

        Include complete behavioral data:
        - behaviorMetrics: {contextSwitchesPerMinute, sessionDuration, applicationFocus, notificationAccumulation, recentAppSequence}
        - systemContext: {activeApp, openWindowCount, isOnVideoCall, ...}
        - baselineDeviation: Double (if testing baseline)

        Set hypothesis field explaining what behavioral feature is being tested.

        Generate realistic, diverse scenarios that explore edge cases not covered by seed scenarios SC-1 to SC-12.

        SCENARIOS TESTED SO FAR:
        """

        for round in previousRounds {
            prompt += "\n\nROUND \(round.id):"
            for (i, scenario) in round.scenarios.enumerated() {
                let eval = round.evaluations[safe: i]
                prompt += """
                \n  \(scenario.id) "\(scenario.name)": \(eval?.passed == true ? "PASSED" : "FAILED") (\(Int((eval?.confidence ?? 0) * 100))%)
                  Description: \(scenario.description)
                  Expected: \(scenario.expectedBehavior.joined(separator: "; "))
                """
                if let reasoning = eval?.reasoning {
                    prompt += "\n  Analysis: \(reasoning)"
                }
                if let mismatches = eval?.mismatches, !mismatches.isEmpty {
                    prompt += "\n  Mismatches: \(mismatches.joined(separator: "; "))"
                }
            }
        }

        let totalSoFar = previousRounds.flatMap(\.scenarios).count
        let nextID = totalSoFar + 1

        prompt += """


        Based on these results, generate 8-10 NEW test scenarios that:
        1. Test BOUNDARY CONDITIONS around rules (exact time thresholds, counts at limits)
        2. Test COMBINATIONS of behaviors not yet tested together
        3. Probe areas where confidence was LOW
        4. Explore SEQUENCES not covered
        5. Each scenario MUST have a HYPOTHESIS explaining why it might reveal a bug
        6. Test BEHAVIORAL edge cases (contrastive pairs, baseline deviations, behavioral velocity)

        Start scenario IDs from "sc-\(nextID)".

        For each step, the weather field determines what the mock analysis will contain:
        - "clear" -> no nudge (nudge_type null)
        - "cloudy" -> usually no nudge unless confidence is high
        - "stormy" -> can have nudge_type "practice" or "encouragement" with appropriate message and practice_id

        IMPORTANT: Include behavioral data in steps to test behavioral stress detection:
        - behaviorMetrics: {contextSwitchesPerMinute (double), sessionDuration (seconds), applicationFocus (0.0-1.0), notificationAccumulation (int), recentAppSequence (array of strings)}
        - systemContext: {activeApp (string), openWindowCount (int), isOnVideoCall (bool), isScreenSharing (bool), batteryLevel (double), timeOfDay (string)}
        - baselineDeviation (double, e.g., 0.0 = no change, 2.5 = 250% above baseline)

        Respond with JSON ONLY (no markdown, no code blocks):
        {
          "scenarios": [
            {
              "id": "sc-N",
              "name": "short name",
              "hypothesis": "Why this test might reveal a bug",
              "description": "What this scenario tests",
              "steps": [
                {
                  "id": "Na",
                  "description": "step description",
                  "weather": "clear|cloudy|stormy",
                  "confidence": 0.0-1.0,
                  "signals": ["signal1", "signal2"],
                  "nudge_type": "practice|encouragement|null",
                  "nudge_message": "message or null",
                  "practice_id": "id or null",
                  "user_action": "dismiss_im_fine|dismiss_later|start_practice|complete_practice|null",
                  "time_delta": seconds_since_last_step,
                  "behavior_metrics": {
                    "context_switches_per_minute": 0.0,
                    "session_duration": 0,
                    "application_focus": 0.0,
                    "notification_accumulation": 0,
                    "recent_app_sequence": []
                  },
                  "system_context": {
                    "active_app": "AppName",
                    "open_window_count": 0,
                    "is_on_video_call": false,
                    "is_screen_sharing": false,
                    "battery_level": 0.0,
                    "time_of_day": "morning|afternoon|evening"
                  },
                  "baseline_deviation": 0.0
                }
              ],
              "expected_behavior": ["expected outcome 1", ...]
            }
          ]
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
            return ["x-api-key": apiKey, "anthropic-version": Self.apiVersion]
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
            "messages": [[
                "role": "user",
                "content": userPrompt
            ]],
            "thinking": [
                "type": "enabled",
                "budget_tokens": thinkingBudget
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 300  // 5 min — Railway proxy has no 150s limit
        for (key, value) in authHeaders() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        var data: Data
        var response: URLResponse
        let maxRetries = 2
        var lastError: Error?
        (data, response) = (Data(), URLResponse())  // placeholders
        for attempt in 0...maxRetries {
            do {
                (data, response) = try await URLSession.shared.data(for: request)
                lastError = nil
                break
            } catch {
                lastError = error
                if attempt < maxRetries {
                    let delay = UInt64((attempt + 1) * 5) * 1_000_000_000  // 5s, 10s
                    print("[ScenarioGenerator] Retry \(attempt + 1)/\(maxRetries) after error: \(error.localizedDescription)")
                    try? await Task.sleep(nanoseconds: delay)
                    continue
                }
            }
        }
        if let lastError {
            throw ClaudeAPIError.networkError(underlying: lastError)
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
            let errorBody = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: httpResponse.statusCode, body: errorBody)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing content: \(errorBody)")
        }

        var thinkingText: String?
        var textContent: String?

        for block in content {
            guard let blockType = block["type"] as? String else { continue }
            switch blockType {
            case "thinking":
                if let thinking = block["thinking"] as? String, !thinking.isEmpty {
                    thinkingText = thinking
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
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "No text content in response")
        }

        return (text: text, thinking: thinkingText)
    }

    // MARK: - Parsing

    private func parseGeneratedScenarios(_ text: String, roundNumber: Int) -> [PlaytestScenario] {
        let jsonString = extractJSON(from: text)

        guard let jsonData = jsonString.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let scenariosArray = root["scenarios"] as? [[String: Any]] else {
            return []
        }

        return scenariosArray.compactMap { scenarioJSON -> PlaytestScenario? in
            guard let id = scenarioJSON["id"] as? String,
                  let name = scenarioJSON["name"] as? String,
                  let description = scenarioJSON["description"] as? String,
                  let stepsArray = scenarioJSON["steps"] as? [[String: Any]],
                  let expectedBehavior = scenarioJSON["expected_behavior"] as? [String] else {
                return nil
            }

            let hypothesis = scenarioJSON["hypothesis"] as? String

            let steps: [ScenarioStep] = stepsArray.compactMap { stepJSON -> ScenarioStep? in
                // Accept both String and numeric id from JSON
                let stepIDStr: String
                if let strID = stepJSON["id"] as? String {
                    stepIDStr = strID
                } else if let numID = stepJSON["id"] as? Int {
                    stepIDStr = "\(numID)"
                } else {
                    return nil
                }

                let stepDescription = stepJSON["description"] as? String ?? ""
                let weather = stepJSON["weather"] as? String ?? "clear"
                let confidence = stepJSON["confidence"] as? Double ?? 0.5
                let signals = stepJSON["signals"] as? [String] ?? []
                let nudgeTypeStr = stepJSON["nudge_type"] as? String
                let nudgeMessage = stepJSON["nudge_message"] as? String
                let practiceID = stepJSON["practice_id"] as? String
                let userActionStr = stepJSON["user_action"] as? String
                let timeDelta = stepJSON["time_delta"] as? TimeInterval ?? 300

                let mockAnalysis: StressAnalysisResponse
                switch weather {
                case "stormy":
                    let nudge = nudgeTypeStr.flatMap { NudgeType(rawValue: $0) }
                    mockAnalysis = .stormy(
                        confidence: confidence,
                        signals: signals,
                        nudge: nudge,
                        message: nudgeMessage,
                        practiceID: practiceID
                    )
                case "cloudy":
                    mockAnalysis = .cloudy(confidence: confidence, signals: signals)
                default:
                    mockAnalysis = .clear(confidence: confidence, signals: signals)
                }

                // Parse behavioral data
                var behaviorMetrics: BehaviorMetrics?
                if let behaviorJSON = stepJSON["behavior_metrics"] as? [String: Any] {
                    behaviorMetrics = BehaviorMetrics(
                        contextSwitchesPerMinute: behaviorJSON["context_switches_per_minute"] as? Double ?? 0.0,
                        sessionDuration: behaviorJSON["session_duration"] as? TimeInterval ?? 0,
                        applicationFocus: behaviorJSON["application_focus"] as? [String: Double] ?? [:],
                        notificationAccumulation: behaviorJSON["notification_accumulation"] as? Int ?? 0,
                        recentAppSequence: behaviorJSON["recent_app_sequence"] as? [String] ?? []
                    )
                }

                var systemContext: SystemContext?
                if let contextJSON = stepJSON["system_context"] as? [String: Any] {
                    systemContext = SystemContext(
                        activeApp: contextJSON["active_app"] as? String ?? "Unknown",
                        activeWindowTitle: contextJSON["active_window_title"] as? String,
                        openWindowCount: contextJSON["open_window_count"] as? Int ?? 0,
                        recentAppSwitches: contextJSON["recent_app_switches"] as? [String] ?? [],
                        pendingNotificationCount: contextJSON["pending_notification_count"] as? Int ?? 0,
                        isOnVideoCall: contextJSON["is_on_video_call"] as? Bool ?? false,
                        isScreenSharing: contextJSON["is_screen_sharing"] as? Bool ?? false,
                        systemUptime: contextJSON["system_uptime"] as? TimeInterval ?? 0,
                        idleTime: contextJSON["idle_time"] as? TimeInterval ?? 0
                    )
                }

                let baselineDeviation = stepJSON["baseline_deviation"] as? Double

                return ScenarioStep(
                    id: stepIDStr,
                    description: stepDescription,
                    mockAnalysis: mockAnalysis,
                    userAction: mapUserAction(userActionStr),
                    timeDelta: timeDelta,
                    behaviorMetrics: behaviorMetrics,
                    systemContext: systemContext,
                    baselineDeviation: baselineDeviation
                )
            }

            // Generate assertions from expected_behavior where possible
            var assertions: [PlaytestAssertion] = []
            for step in steps {
                // If step has no nudge type in mock analysis, assert no nudge
                if step.mockAnalysis.nudgeType == nil {
                    assertions.append(PlaytestAssertion(
                        stepID: step.id,
                        field: .nudgeShouldShow,
                        expected: "false"
                    ))
                }
            }

            return PlaytestScenario(
                id: id,
                name: name,
                description: description,
                steps: steps,
                round: roundNumber,
                expectedBehavior: expectedBehavior,
                hypothesis: hypothesis,
                assertions: assertions
            )
        }
    }

    private func mapUserAction(_ action: String?) -> PlaytestUserAction? {
        switch action {
        case "dismiss_im_fine": return .dismissImFine
        case "dismiss_later": return .dismissLater
        case "start_practice": return .startPractice
        case "complete_practice": return .completePractice
        default: return nil
        }
    }

    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code blocks first
        if let range = text.range(of: "```json"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = text.range(of: "```"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Try to find raw JSON object
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValid(_ scenario: PlaytestScenario) -> Bool {
        !scenario.steps.isEmpty && !scenario.expectedBehavior.isEmpty
            && scenario.steps.allSatisfy { !$0.id.isEmpty }
    }
}

// Uses Array.subscript(safe:) from ResultEvaluator.swift
