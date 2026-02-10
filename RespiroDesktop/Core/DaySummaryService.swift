import Foundation

actor DaySummaryService {
    private let apiKey: String

    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-opus-4-6-20250219"
    private static let apiVersion = "2023-06-01"
    private static let maxTokens = 4096

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

    init() throws {
        guard let key = APIKeyManager.getAPIKey() else {
            throw ClaudeAPIError.noAPIKey
        }
        self.apiKey = key
    }

    init(apiKey: String) {
        self.apiKey = apiKey
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
        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": Self.maxTokens,
            "system": Self.systemPrompt,
            "messages": [[
                "role": "user",
                "content": userMessage
            ]]
        ]

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
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
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            let body = String(data: data, encoding: .utf8) ?? "unreadable"
            throw ClaudeAPIError.invalidResponse(statusCode: 200, body: "Missing text content: \(body)")
        }

        let jsonString = extractJSON(from: text)

        do {
            let jsonData = Data(jsonString.utf8)
            return try JSONDecoder().decode(DaySummaryResponse.self, from: jsonData)
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
