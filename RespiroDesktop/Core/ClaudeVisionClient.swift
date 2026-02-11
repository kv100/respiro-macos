import Foundation

// MARK: - Screenshot Context

struct ScreenshotContext: Sendable {
    let time: String
    let dayOfWeek: String
    let recentEntries: String
    let lastNudgeMinutesAgo: Int?
    let lastNudgeType: String?
    let dismissalCount2h: Int
    let preferredPractices: [String]
    let learnedPatterns: String?
}

// MARK: - Errors

enum ClaudeAPIError: Error, LocalizedError {
    case noAPIKey
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int, body: String)
    case decodingError(underlying: Error)
    case rateLimited
    case serverError(statusCode: Int)
    case dailyLimitReached

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key found. Set ANTHROPIC_API_KEY environment variable, Info.plist key, or enter in Settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code, let body):
            return "Invalid response (\(code)): \(body)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .rateLimited:
            return "Rate limited by Claude API"
        case .serverError(let code):
            return "Server error (\(code))"
        case .dailyLimitReached:
            return "Daily API call limit (100) reached"
        }
    }
}

// MARK: - Claude Vision Client

struct ClaudeVisionClient: Sendable {
    let apiKey: String

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-opus-4-6-20250219"
    private static let apiVersion = "2023-06-01"
    // maxTokens now scales with effort level — see EffortLevel.maxResponseTokens
    private static let maxDailyCalls = 100
    private static let retryDelay: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds
    private static let maxToolRounds = 3 // Prevent infinite tool use loops

    // MARK: - Tool Definitions

    nonisolated(unsafe) private static let toolDefinitions: [[String: Any]] = [
        [
            "name": "get_practice_catalog",
            "description": "Get available stress-relief practices with descriptions and durations. Call this to see what practices are available before making a recommendation.",
            "input_schema": [
                "type": "object",
                "properties": [:] as [String: Any]
            ]
        ],
        [
            "name": "get_user_history",
            "description": "Get user's recent practice sessions, weather patterns, and preferences. Use this to understand what has worked for the user before.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "days": [
                        "type": "integer",
                        "description": "Number of days of history to retrieve (default 7)"
                    ]
                ]
            ]
        ],
        [
            "name": "suggest_practice",
            "description": "Recommend a specific practice to the user with reasoning. Call this after reviewing the catalog and optionally the user's history to make your final recommendation.",
            "input_schema": [
                "type": "object",
                "properties": [
                    "practice_id": [
                        "type": "string",
                        "description": "The ID of the practice to recommend"
                    ],
                    "reason": [
                        "type": "string",
                        "description": "Why this practice is recommended, in user-friendly language"
                    ],
                    "urgency": [
                        "type": "string",
                        "enum": ["low", "medium", "high"],
                        "description": "How urgent the recommendation is"
                    ]
                ],
                "required": ["practice_id", "reason", "urgency"]
            ]
        ]
    ]

    private static let systemPrompt = """
        You are Respiro, a calm stress detection assistant in a macOS menu bar app.
        You analyze screenshots to assess stress level using a weather metaphor.

        OBSERVE: visual cues — tab count, notification volume, app switching, video calls,
        error messages, deadline content. NOT message content, names, or documents.

        WEATHER:
        - clear: relaxed, focused, organized, single task
        - cloudy: mild tension, multiple apps, moderate inbox
        - stormy: high stress — overflowing notifications, errors, call fatigue, chaos

        NUDGE PHILOSOPHY:
        - You are a gentle friend, NOT an alarm. Confidence >= 0.6 to suggest practice.
        - Prefer .encouragement over .practice when uncertain.
        - NEVER nudge during presentations or screen share.
        - After 3 consecutive dismissals: nudge_type = null for next 2 analyses.

        PRACTICE SELECTION:
        - Stormy + high confidence → breathing (fast-acting)
        - Cloudy for 3+ checks → cognitive (STOP, Self-Compassion)
        - Post-meeting → grounding (transition to calm)

        NEVER: read/quote messages, mention names, reference documents, diagnose conditions.

        RESPOND WITH JSON ONLY:
        { "weather", "confidence", "signals", "nudge_type", "nudge_message", "suggested_practice_id" }
        """

    /// System prompt for tool use mode — instructs AI to use tools for practice selection
    private static let toolUseSystemPrompt = """
        You are Respiro, a calm stress detection assistant in a macOS menu bar app.
        You analyze screenshots to assess stress level using a weather metaphor.

        OBSERVE: visual cues — tab count, notification volume, app switching, video calls,
        error messages, deadline content. NOT message content, names, or documents.

        WEATHER:
        - clear: relaxed, focused, organized, single task
        - cloudy: mild tension, multiple apps, moderate inbox
        - stormy: high stress — overflowing notifications, errors, call fatigue, chaos

        NUDGE PHILOSOPHY:
        - You are a gentle friend, NOT an alarm. Confidence >= 0.6 to suggest practice.
        - Prefer .encouragement over .practice when uncertain.
        - NEVER nudge during presentations or screen share.
        - After 3 consecutive dismissals: nudge_type = null for next 2 analyses.

        PRACTICE SELECTION WORKFLOW:
        When you decide a nudge_type of "practice" is appropriate:
        1. Call get_practice_catalog to see available practices
        2. Optionally call get_user_history to understand what has worked before
        3. Call suggest_practice with your recommendation and reasoning
        Think carefully between each tool call about what the user needs.

        GUIDELINES:
        - Stormy + high confidence → breathing (fast-acting)
        - Cloudy for 3+ checks → cognitive (STOP, Self-Compassion)
        - Post-meeting → grounding (transition to calm)
        - Consider user history: repeat what worked, avoid what was dismissed

        NEVER: read/quote messages, mention names, reference documents, diagnose conditions.

        RESPOND WITH JSON ONLY (after using tools if needed):
        { "weather", "confidence", "signals", "nudge_type", "nudge_message", "suggested_practice_id" }
        """

    // MARK: - Init

    init() throws {
        guard let key = APIKeyManager.getAPIKey() else {
            throw ClaudeAPIError.noAPIKey
        }
        self.apiKey = key
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public API

    func analyzeScreenshot(_ imageData: Data, context: ScreenshotContext, effortLevel: EffortLevel = .low) async throws -> StressAnalysisResponse {
        try checkDailyLimit()

        let userPrompt = buildUserPrompt(context: context)
        let requestBody = buildRequestBody(imageData: imageData, userPrompt: userPrompt, effortLevel: effortLevel)
        let request = try buildURLRequest(body: requestBody)

        do {
            var result = try await performRequest(request, effortLevel: effortLevel)
            result.effortLevel = effortLevel
            return result
        } catch let error as ClaudeAPIError {
            // Retry once on network error
            if case .networkError = error {
                try await Task.sleep(nanoseconds: Self.retryDelay)
                var result = try await performRequest(request, effortLevel: effortLevel)
                result.effortLevel = effortLevel
                return result
            }
            throw error
        }
    }

    // MARK: - Tool Use API

    /// Analyze screenshot with Claude Tool Use — AI calls tools to select a practice.
    /// This showcases interleaved thinking between tool calls (Opus 4.6 feature).
    ///
    /// Flow: send screenshot + tools -> AI reasons -> calls get_practice_catalog ->
    /// AI reasons about options -> optionally calls get_user_history ->
    /// AI reasons -> calls suggest_practice (final answer) -> parse response
    func analyzeScreenshotWithTools(
        _ imageData: Data,
        context: ScreenshotContext,
        effortLevel: EffortLevel = .high,
        toolContext: ToolContext
    ) async throws -> StressAnalysisResponse {
        try checkDailyLimit()

        let userPrompt = buildUserPrompt(context: context)

        // Build initial messages with screenshot
        let initialMessages: [[String: Any]] = [[
            "role": "user",
            "content": [
                [
                    "type": "image",
                    "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": imageData.base64EncodedString()
                    ]
                ],
                [
                    "type": "text",
                    "text": userPrompt
                ]
            ]
        ]]

        var result = try await runToolUseLoop(
            messages: initialMessages,
            effortLevel: effortLevel,
            toolContext: toolContext
        )
        result.effortLevel = effortLevel
        incrementDailyCallCount()
        return result
    }

    // MARK: - Tool Use Loop

    /// Multi-turn loop: send request, handle tool_use blocks, send tool_result, repeat.
    /// Max `maxToolRounds` rounds to prevent infinite loops.
    private func runToolUseLoop(
        messages: [[String: Any]],
        effortLevel: EffortLevel,
        toolContext: ToolContext
    ) async throws -> StressAnalysisResponse {
        var conversationMessages = messages
        var allThinkingParts: [String] = []
        var allToolCalls: [ToolCall] = []
        var suggestedPracticeID: String?
        var practiceReason: String?

        for round in 0..<Self.maxToolRounds {
            // Build request body with tools and thinking
            let body = buildToolUseRequestBody(
                messages: conversationMessages,
                effortLevel: effortLevel
            )
            let request = try buildURLRequest(body: body)

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

            // Parse the response
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]] else {
                let body = String(data: data, encoding: .utf8) ?? "unreadable"
                throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing content: \(body)")
            }

            let stopReason = json["stop_reason"] as? String

            // Process content blocks: collect thinking, text, and tool_use
            var textContent: String?
            var toolUseBlocks: [(id: String, name: String, input: [String: Any])] = []

            for block in content {
                guard let blockType = block["type"] as? String else { continue }

                switch blockType {
                case "thinking":
                    if let thinking = block["thinking"] as? String, !thinking.isEmpty {
                        allThinkingParts.append(thinking)
                    }
                case "text":
                    if let text = block["text"] as? String {
                        textContent = text
                    }
                case "tool_use":
                    if let toolId = block["id"] as? String,
                       let toolName = block["name"] as? String {
                        let toolInput = block["input"] as? [String: Any] ?? [:]
                        toolUseBlocks.append((id: toolId, name: toolName, input: toolInput))

                        // Log the tool call
                        let inputJSON = (try? JSONSerialization.data(withJSONObject: toolInput))
                            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
                        allToolCalls.append(ToolCall(name: toolName, input: inputJSON))
                    }
                default:
                    break
                }
            }

            // Check if we got a suggest_practice tool call — this is the final answer for practice
            for toolUse in toolUseBlocks {
                if toolUse.name == "suggest_practice" {
                    suggestedPracticeID = toolUse.input["practice_id"] as? String
                    practiceReason = toolUse.input["reason"] as? String
                }
            }

            // If stop_reason is "end_turn" or we have text content and no tool_use, we're done
            if stopReason == "end_turn" || (toolUseBlocks.isEmpty && textContent != nil) {
                // Parse the final text response as JSON
                if let text = textContent {
                    let jsonString = extractJSON(from: text)
                    do {
                        let jsonData = Data(jsonString.utf8)
                        var analysisResponse = try JSONDecoder().decode(StressAnalysisResponse.self, from: jsonData)
                        if !allThinkingParts.isEmpty {
                            analysisResponse.thinkingText = allThinkingParts.joined(separator: "\n\n")
                        }
                        if !allToolCalls.isEmpty {
                            analysisResponse.toolUseLog = allToolCalls
                        }
                        // Override practice ID/reason from suggest_practice tool if used
                        if let practiceID = suggestedPracticeID {
                            analysisResponse = StressAnalysisResponse(
                                weather: analysisResponse.weather,
                                confidence: analysisResponse.confidence,
                                signals: analysisResponse.signals,
                                nudgeType: analysisResponse.nudgeType,
                                nudgeMessage: analysisResponse.nudgeMessage,
                                suggestedPracticeID: practiceID
                            )
                            analysisResponse.thinkingText = allThinkingParts.isEmpty ? nil : allThinkingParts.joined(separator: "\n\n")
                            analysisResponse.toolUseLog = allToolCalls.isEmpty ? nil : allToolCalls
                            analysisResponse.practiceReason = practiceReason
                        }
                        return analysisResponse
                    } catch {
                        throw ClaudeAPIError.decodingError(underlying: error)
                    }
                }

                // No text content but we have suggest_practice — build minimal response
                // This shouldn't normally happen, but handle gracefully
                if suggestedPracticeID != nil {
                    // We need the weather analysis — this is a fallback
                    var fallback = StressAnalysisResponse(
                        weather: "cloudy",
                        confidence: 0.5,
                        signals: ["tool_use_only_response"],
                        nudgeType: "practice",
                        nudgeMessage: practiceReason ?? "Take a moment for yourself",
                        suggestedPracticeID: suggestedPracticeID
                    )
                    fallback.thinkingText = allThinkingParts.isEmpty ? nil : allThinkingParts.joined(separator: "\n\n")
                    fallback.toolUseLog = allToolCalls.isEmpty ? nil : allToolCalls
                    fallback.practiceReason = practiceReason
                    return fallback
                }

                // No usable response
                let body = String(data: data, encoding: .utf8) ?? "unreadable"
                throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "No parseable response: \(body)")
            }

            // We have tool_use blocks — handle them and continue the loop
            guard stopReason == "tool_use" || !toolUseBlocks.isEmpty else {
                // Unexpected stop reason
                let body = String(data: data, encoding: .utf8) ?? "unreadable"
                throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Unexpected stop: \(body)")
            }

            // Build tool results and add assistant + user messages for next round
            // First: add the assistant's response (with tool_use blocks) as-is
            let assistantContent = content
            conversationMessages.append([
                "role": "assistant",
                "content": assistantContent
            ])

            // Then: add user message with tool_result blocks
            var toolResults: [[String: Any]] = []
            for toolUse in toolUseBlocks {
                let resultContent = handleToolCall(
                    name: toolUse.name,
                    input: toolUse.input,
                    toolContext: toolContext
                )
                toolResults.append([
                    "type": "tool_result",
                    "tool_use_id": toolUse.id,
                    "content": resultContent
                ])
            }

            conversationMessages.append([
                "role": "user",
                "content": toolResults
            ])

            // If this was the last round and we have suggest_practice, build response
            if round == Self.maxToolRounds - 1 && suggestedPracticeID != nil {
                var fallback = StressAnalysisResponse(
                    weather: "cloudy",
                    confidence: 0.5,
                    signals: ["max_tool_rounds_reached"],
                    nudgeType: "practice",
                    nudgeMessage: practiceReason ?? "Take a moment for yourself",
                    suggestedPracticeID: suggestedPracticeID
                )
                fallback.thinkingText = allThinkingParts.isEmpty ? nil : allThinkingParts.joined(separator: "\n\n")
                fallback.toolUseLog = allToolCalls.isEmpty ? nil : allToolCalls
                fallback.practiceReason = practiceReason
                return fallback
            }
        }

        // Should not reach here, but handle gracefully
        throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Tool use loop exhausted without response")
    }

    // MARK: - Tool Call Handlers

    /// Handle a single tool call and return the result content string
    private func handleToolCall(name: String, input: [String: Any], toolContext: ToolContext) -> String {
        switch name {
        case "get_practice_catalog":
            return buildPracticeCatalogJSON()

        case "get_user_history":
            return buildUserHistoryJSON(toolContext: toolContext)

        case "suggest_practice":
            // suggest_practice is the FINAL answer — acknowledge it
            let practiceId = input["practice_id"] as? String ?? "unknown"
            let reason = input["reason"] as? String ?? ""
            return "{\"status\":\"accepted\",\"practice_id\":\"\(practiceId)\",\"reason\":\"\(reason)\"}"

        default:
            return "{\"error\":\"Unknown tool: \(name)\"}"
        }
    }

    /// Build JSON representation of the practice catalog for tool response
    private func buildPracticeCatalogJSON() -> String {
        let practices = PracticeCatalog.all.map { practice -> [String: Any] in
            [
                "id": practice.id,
                "title": practice.title,
                "category": practice.category.rawValue,
                "duration_seconds": practice.duration,
                "steps": practice.steps.map { $0.instruction }
            ]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: ["practices": practices]),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"practices\":[]}"
        }
        return jsonString
    }

    /// Build JSON representation of user history from pre-fetched ToolContext
    private func buildUserHistoryJSON(toolContext: ToolContext) -> String {
        let result: [String: Any] = [
            "practice_sessions": toolContext.practiceHistory,
            "weather_history": toolContext.weatherHistory,
            "preferred_practices": toolContext.preferredPractices,
            "summary": "User has completed \(toolContext.preferredPractices.count) preferred practices"
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: result),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"practice_sessions\":[],\"weather_history\":[],\"preferred_practices\":[]}"
        }
        return jsonString
    }

    // MARK: - Tool Use Request Body

    private func buildToolUseRequestBody(
        messages: [[String: Any]],
        effortLevel: EffortLevel
    ) -> [String: Any] {
        var body: [String: Any] = [
            "model": Self.model,
            "max_tokens": effortLevel.budgetTokens + effortLevel.maxResponseTokens,
            "system": Self.toolUseSystemPrompt,
            "messages": messages,
            "tools": Self.toolDefinitions
        ]

        // Enable adaptive thinking with budget scaled to effort level
        body["thinking"] = [
            "type": "enabled",
            "budget_tokens": effortLevel.budgetTokens
        ]

        return body
    }

    // MARK: - Request Building

    private func buildUserPrompt(context: ScreenshotContext) -> String {
        var prompt = """
            Analyze this macOS desktop screenshot. Determine stress level as weather.

            CONTEXT:
            - Time: \(context.time) (\(context.dayOfWeek))
            - Recent weather: \(context.recentEntries)
            """

        if let minutesAgo = context.lastNudgeMinutesAgo, let nudgeType = context.lastNudgeType {
            prompt += "\n- Last nudge: \(minutesAgo) min ago (\(nudgeType))"
        } else {
            prompt += "\n- Last nudge: none"
        }

        prompt += """

            - Dismissals (2h): \(context.dismissalCount2h)
            - Preferences: \(context.preferredPractices.joined(separator: ", "))
            - Override patterns: \(context.learnedPatterns ?? "none")

            AVAILABLE PRACTICES: physiological-sigh, box-breathing, grounding-54321, stop-technique, self-compassion, extended-exhale, thought-defusion, coherent-breathing

            Respond JSON only.
            """

        return prompt
    }

    private func buildRequestBody(imageData: Data, userPrompt: String, effortLevel: EffortLevel = .low) -> [String: Any] {
        var body: [String: Any] = [
            "model": Self.model,
            "max_tokens": effortLevel.budgetTokens + effortLevel.maxResponseTokens,
            "system": Self.systemPrompt,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": imageData.base64EncodedString()
                        ]
                    ],
                    [
                        "type": "text",
                        "text": userPrompt
                    ]
                ]
            ]]
        ]

        // Enable adaptive thinking with budget scaled to effort level
        body["thinking"] = [
            "type": "enabled",
            "budget_tokens": effortLevel.budgetTokens
        ]

        return body
    }

    private func buildURLRequest(body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    // MARK: - Request Execution

    private func performRequest(_ request: URLRequest, effortLevel: EffortLevel = .low) async throws -> StressAnalysisResponse {
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

        // Parse Claude Messages API response to extract text + thinking content
        var analysisResponse = try parseMessagesResponse(data)
        analysisResponse.effortLevel = effortLevel
        incrementDailyCallCount()
        return analysisResponse
    }

    // MARK: - Response Parsing

    private func parseMessagesResponse(_ data: Data) throws -> StressAnalysisResponse {
        // Claude Messages API returns: { "content": [{ "type": "thinking", "thinking": "..." }, { "type": "text", "text": "..." }] }
        let json: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Not a JSON object")
            }
            json = parsed
        } catch let error as ClaudeAPIError {
            throw error
        } catch {
            throw ClaudeAPIError.decodingError(underlying: error)
        }

        guard let content = json["content"] as? [[String: Any]] else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing content array: \(body)")
        }

        // Iterate content blocks: collect thinking text and find the text block with JSON
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

        // Extract JSON from the text — Claude may wrap it in markdown code blocks
        let jsonString = extractJSON(from: text)

        do {
            let jsonData = Data(jsonString.utf8)
            var response = try JSONDecoder().decode(StressAnalysisResponse.self, from: jsonData)
            // Attach thinking text if any thinking blocks were present
            if !thinkingParts.isEmpty {
                response.thinkingText = thinkingParts.joined(separator: "\n\n")
            }
            return response
        } catch {
            throw ClaudeAPIError.decodingError(underlying: error)
        }
    }

    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code blocks first
        if let range = text.range(of: "```json"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let range = text.range(of: "```"),
           let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
            return String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Try to find raw JSON object
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Daily Call Limit

    private static let dailyCountKey = "respiro_daily_api_calls"
    private static let dailyDateKey = "respiro_daily_api_date"

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func currentDailyCount() -> Int {
        let defaults = UserDefaults.standard
        let storedDate = defaults.string(forKey: Self.dailyDateKey) ?? ""
        if storedDate != todayString() {
            return 0
        }
        return defaults.integer(forKey: Self.dailyCountKey)
    }

    private func checkDailyLimit() throws {
        if currentDailyCount() >= Self.maxDailyCalls {
            throw ClaudeAPIError.dailyLimitReached
        }
    }

    private func incrementDailyCallCount() {
        let defaults = UserDefaults.standard
        let today = todayString()
        let storedDate = defaults.string(forKey: Self.dailyDateKey) ?? ""

        if storedDate != today {
            defaults.set(today, forKey: Self.dailyDateKey)
            defaults.set(1, forKey: Self.dailyCountKey)
        } else {
            let current = defaults.integer(forKey: Self.dailyCountKey)
            defaults.set(current + 1, forKey: Self.dailyCountKey)
        }
    }

    var dailyCallCount: Int {
        currentDailyCount()
    }

    var isApproachingDailyLimit: Bool {
        currentDailyCount() >= 80
    }

    // MARK: - Streaming API

    /// Streaming analysis — yields thinking text progressively via callback.
    /// Parses SSE (Server-Sent Events) from the Claude Messages API streaming endpoint.
    /// The `onThinkingUpdate` callback is called with accumulated thinking text as it arrives.
    func analyzeScreenshotStreaming(
        _ imageData: Data,
        context: ScreenshotContext,
        effortLevel: EffortLevel = .high,
        onThinkingUpdate: @escaping @Sendable (String) -> Void
    ) async throws -> StressAnalysisResponse {
        try checkDailyLimit()

        let userPrompt = buildUserPrompt(context: context)
        var requestBody = buildRequestBody(imageData: imageData, userPrompt: userPrompt, effortLevel: effortLevel)
        requestBody["stream"] = true

        let request = try buildURLRequest(body: requestBody)

        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
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
            // For non-200, collect the full body for error reporting
            var errorBody = ""
            for try await line in bytes.lines {
                errorBody += line
            }
            throw ClaudeAPIError.invalidResponse(statusCode: httpResponse.statusCode, body: errorBody)
        }

        // Parse SSE stream
        var accumulatedThinking = ""
        var accumulatedText = ""

        for try await line in bytes.lines {
            // SSE lines: "data: {json}" or "data: [DONE]"
            guard line.hasPrefix("data: ") else { continue }

            let payload = String(line.dropFirst(6))

            if payload == "[DONE]" {
                break
            }

            guard let eventData = payload.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
                  let eventType = event["type"] as? String else {
                continue
            }

            switch eventType {
            case "content_block_delta":
                guard let delta = event["delta"] as? [String: Any],
                      let deltaType = delta["type"] as? String else { continue }

                switch deltaType {
                case "thinking_delta":
                    if let thinkingChunk = delta["thinking"] as? String {
                        accumulatedThinking += thinkingChunk
                        onThinkingUpdate(accumulatedThinking)
                    }
                case "text_delta":
                    if let textChunk = delta["text"] as? String {
                        accumulatedText += textChunk
                    }
                default:
                    break
                }

            case "message_delta":
                // Contains stop_reason — stream is ending
                break

            case "error":
                let errorMsg = (event["error"] as? [String: Any])?["message"] as? String ?? "Unknown streaming error"
                throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Stream error: \(errorMsg)")

            default:
                // content_block_start, content_block_stop, message_start, message_stop, ping — skip
                break
            }
        }

        // Parse accumulated text as JSON response
        guard !accumulatedText.isEmpty else {
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "No text content received from stream")
        }

        let jsonString = extractJSON(from: accumulatedText)

        do {
            let jsonData = Data(jsonString.utf8)
            var analysisResponse = try JSONDecoder().decode(StressAnalysisResponse.self, from: jsonData)
            if !accumulatedThinking.isEmpty {
                analysisResponse.thinkingText = accumulatedThinking
            }
            analysisResponse.effortLevel = effortLevel
            incrementDailyCallCount()
            return analysisResponse
        } catch {
            throw ClaudeAPIError.decodingError(underlying: error)
        }
    }
}
