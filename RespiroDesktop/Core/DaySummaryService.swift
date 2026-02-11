import Foundation

actor DaySummaryService {
    private let mode: ClaudeVisionClient.Mode

    private var endpoint: URL {
        switch mode {
        case .direct:
            return URL(string: "https://api.anthropic.com/v1/messages")!
        case .proxy(let url, _, _):
            return URL(string: "\(url)/functions/v1/claude-proxy")!
        }
    }

    private static let model = "claude-opus-4-6-20250219"
    private static let apiVersion = "2023-06-01"
    private static let maxTokens = EffortLevel.max.budgetTokens + EffortLevel.max.maxResponseTokens

    private static let systemPrompt = """
        You are Respiro's end-of-day reflection assistant. Analyze the user's full day \
        of stress data and provide a warm, insightful summary.

        DATA PROVIDED:
        - Stress entries with timestamps, weather, confidence, signals
        - Practice sessions with before/after weather, completion status
        - Dismissal events showing when user said "I'm Fine"

        RESPOND AS JSON ONLY:
        { "overall_mood", "stress_pattern", "effective_practice", "recommendation", "day_score" }

        - overall_mood: 1-2 sentences describing the day using weather metaphors
        - stress_pattern: 1-2 sentences about when and why stress peaked
        - effective_practice: 1-2 sentences about which practice helped most
        - recommendation: 1-2 sentences of advice for tomorrow
        - day_score: integer 1-10 overall wellness score

        Be warm and personal. Reference specific times and patterns. Celebrate improvements.
        Keep each field to 1-2 sentences.
        """

    /// Auto-detect mode: proxy first (always available)
    init() {
        let deviceID = DeviceID.current
        self.mode = .proxy(
            supabaseURL: RespiroConfig.supabaseURL,
            anonKey: RespiroConfig.supabaseAnonKey,
            deviceID: deviceID
        )
    }

    /// Direct mode (BYOK)
    init(apiKey: String) {
        self.mode = .direct(apiKey: apiKey)
    }

    /// Explicit proxy mode
    init(supabaseURL: String, anonKey: String, deviceID: String) {
        self.mode = .proxy(supabaseURL: supabaseURL, anonKey: anonKey, deviceID: deviceID)
    }

    // MARK: - Mode Helpers

    private func authHeaders() -> [String: String] {
        switch mode {
        case .direct(let apiKey):
            return [
                "x-api-key": apiKey,
                "anthropic-version": Self.apiVersion,
            ]
        case .proxy(_, let anonKey, let deviceID):
            return [
                "Authorization": "Bearer \(anonKey)",
                "apikey": anonKey,
                "x-device-id": deviceID,
            ]
        }
    }

    func generateDaySummary(
        entries: [StressEntrySnapshot],
        practices: [PracticeSessionSnapshot],
        dismissals: [DismissalSnapshot]
    ) async throws -> DaySummaryResponse {
        let userMessage = buildUserMessage(entries: entries, practices: practices, dismissals: dismissals)
        return try await sendTextMessage(userMessage: userMessage)
    }

    // MARK: - Private

    private func buildUserMessage(
        entries: [StressEntrySnapshot],
        practices: [PracticeSessionSnapshot],
        dismissals: [DismissalSnapshot]
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"

        var message = "Here is my full day of stress monitoring data:\n\n"

        // Stress entries
        message += "STRESS ENTRIES (\(entries.count) total):\n"
        for entry in entries {
            let time = dateFormatter.string(from: entry.timestamp)
            message += "- \(time): weather=\(entry.weather), confidence=\(String(format: "%.1f", entry.confidence)), signals=\(entry.signals.joined(separator: ", "))"
            if let nudge = entry.nudgeType {
                message += ", nudge=\(nudge)"
            }
            message += "\n"
        }

        // Practice sessions
        message += "\nPRACTICE SESSIONS (\(practices.count) total):\n"
        for session in practices {
            let time = dateFormatter.string(from: session.startedAt)
            message += "- \(time): \(session.practiceID), before=\(session.weatherBefore)"
            if let after = session.weatherAfter {
                message += ", after=\(after)"
            }
            message += ", completed=\(session.wasCompleted)"
            if let helped = session.whatHelped, !helped.isEmpty {
                message += ", helped=\(helped.joined(separator: ", "))"
            }
            message += "\n"
        }

        // Dismissals
        message += "\nDISMISSALS (\(dismissals.count) total):\n"
        for dismissal in dismissals {
            let time = dateFormatter.string(from: dismissal.timestamp)
            message += "- \(time): type=\(dismissal.dismissalType), aiWeather=\(dismissal.aiDetectedWeather)\n"
        }

        message += "\nPlease provide your end-of-day reflection as JSON."
        return message
    }

    private func sendTextMessage(userMessage: String) async throws -> DaySummaryResponse {
        var body: [String: Any] = [
            "model": Self.model,
            "max_tokens": Self.maxTokens,
            "system": Self.systemPrompt,
            "messages": [[
                "role": "user",
                "content": userMessage
            ]]
        ]

        // Enable adaptive thinking with max effort for day reflection
        body["thinking"] = [
            "type": "enabled",
            "budget_tokens": EffortLevel.max.budgetTokens
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

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            if httpResponse.statusCode == 429 {
                throw ClaudeAPIError.rateLimited
            }
            if httpResponse.statusCode >= 500 {
                throw ClaudeAPIError.serverError(statusCode: httpResponse.statusCode)
            }
            throw ClaudeAPIError.invalidResponse(statusCode: httpResponse.statusCode, body: body)
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> DaySummaryResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing content: \(body)")
        }

        // Iterate content blocks: collect thinking and find text with JSON
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

        let jsonString = extractJSON(from: text)

        do {
            let jsonData = Data(jsonString.utf8)
            var response = try JSONDecoder().decode(DaySummaryResponse.self, from: jsonData)
            if !thinkingParts.isEmpty {
                response.thinkingText = thinkingParts.joined(separator: "\n\n")
            }
            return response
        } catch {
            throw ClaudeAPIError.decodingError(underlying: error)
        }
    }

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

// MARK: - Sendable snapshots for passing SwiftData objects across isolation boundaries

struct StressEntrySnapshot: Sendable {
    let timestamp: Date
    let weather: String
    let confidence: Double
    let signals: [String]
    let nudgeType: String?
    let nudgeMessage: String?
}

struct PracticeSessionSnapshot: Sendable {
    let practiceID: String
    let startedAt: Date
    let weatherBefore: String
    let weatherAfter: String?
    let wasCompleted: Bool
    let whatHelped: [String]?
}

struct DismissalSnapshot: Sendable {
    let timestamp: Date
    let aiDetectedWeather: String
    let dismissalType: String
}
