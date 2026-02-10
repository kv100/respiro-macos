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
    private static let maxTokens = 1024
    private static let maxDailyCalls = 100
    private static let retryDelay: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds

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

    func analyzeScreenshot(_ imageData: Data, context: ScreenshotContext) async throws -> StressAnalysisResponse {
        try checkDailyLimit()

        let userPrompt = buildUserPrompt(context: context)
        let requestBody = buildRequestBody(imageData: imageData, userPrompt: userPrompt)
        let request = try buildURLRequest(body: requestBody)

        do {
            return try await performRequest(request)
        } catch let error as ClaudeAPIError {
            // Retry once on network error
            if case .networkError = error {
                try await Task.sleep(nanoseconds: Self.retryDelay)
                return try await performRequest(request)
            }
            throw error
        }
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

    private func buildRequestBody(imageData: Data, userPrompt: String) -> [String: Any] {
        [
            "model": Self.model,
            "max_tokens": Self.maxTokens,
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

    private func performRequest(_ request: URLRequest) async throws -> StressAnalysisResponse {
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

        // Parse Claude Messages API response to extract text content
        let analysisResponse = try parseMessagesResponse(data)
        incrementDailyCallCount()
        return analysisResponse
    }

    // MARK: - Response Parsing

    private func parseMessagesResponse(_ data: Data) throws -> StressAnalysisResponse {
        // Claude Messages API returns: { "content": [{ "type": "text", "text": "..." }] }
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

        guard let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing text content: \(body)")
        }

        // Extract JSON from the text — Claude may wrap it in markdown code blocks
        let jsonString = extractJSON(from: text)

        do {
            let jsonData = Data(jsonString.utf8)
            return try JSONDecoder().decode(StressAnalysisResponse.self, from: jsonData)
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
}
