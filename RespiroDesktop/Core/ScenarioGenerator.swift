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
            thinkingBudget: 10240,
            maxTokens: 4096
        )
        let generated = parseGeneratedScenarios(response.text, roundNumber: roundNumber)
        return generated.filter { isValid($0) }
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


        Based on these results, generate 3-5 NEW test scenarios that:
        1. Test BOUNDARY CONDITIONS around rules (exact time thresholds, counts at limits)
        2. Test COMBINATIONS of behaviors not yet tested together
        3. Probe areas where confidence was LOW
        4. Explore SEQUENCES not covered
        5. Each scenario MUST have a HYPOTHESIS explaining why it might reveal a bug

        Start scenario IDs from "sc-\(nextID)".

        For each step, the weather field determines what the mock analysis will contain:
        - "clear" -> no nudge (nudge_type null)
        - "cloudy" -> usually no nudge unless confidence is high
        - "stormy" -> can have nudge_type "practice" or "encouragement" with appropriate message and practice_id

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
                  "time_delta": seconds_since_last_step
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
        case .proxy(let url, _, _):
            return URL(string: "\(url)/functions/v1/claude-proxy")!
        }
    }

    private func authHeaders() -> [String: String] {
        switch mode {
        case .direct(let apiKey):
            return ["x-api-key": apiKey, "anthropic-version": Self.apiVersion]
        case .proxy(_, let anonKey, let deviceID):
            return ["Authorization": "Bearer \(anonKey)", "apikey": anonKey, "x-device-id": deviceID]
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

            let steps: [ScenarioStep] = stepsArray.compactMap { stepJSON in
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

                return ScenarioStep(
                    id: stepIDStr,
                    description: stepDescription,
                    mockAnalysis: mockAnalysis,
                    userAction: mapUserAction(userActionStr),
                    timeDelta: timeDelta
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
