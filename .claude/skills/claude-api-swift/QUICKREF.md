# Claude API from Swift — Quick Reference

## Endpoint & Auth

```swift
// Direct mode
let url = URL(string: "https://api.anthropic.com/v1/messages")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
request.setValue("application/json", forHTTPHeaderField: "content-type")

// Proxy mode (Supabase Edge Function)
let url = URL(string: "\(supabaseURL)/functions/v1/claude-proxy")!
request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
request.setValue(anonKey, forHTTPHeaderField: "apikey")
request.setValue(deviceID, forHTTPHeaderField: "x-device-id")
```

## Model

```swift
// ALWAYS use Opus 4.6 — never GPT, never Sonnet in production
private static let model = "claude-opus-4-6"
```

## Vision API (Screenshot Analysis)

```swift
let body: [String: Any] = [
    "model": "claude-opus-4-6",
    "max_tokens": effortLevel.budgetTokens + effortLevel.maxResponseTokens,
    "system": systemPrompt,
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
```

## Extended Thinking

```swift
// Enable adaptive thinking with budget scaled to effort level
body["thinking"] = [
    "type": "enabled",
    "budget_tokens": effortLevel.budgetTokens
]

// Response contains thinking + text blocks:
// { "content": [
//     { "type": "thinking", "thinking": "..." },
//     { "type": "text", "text": "{json}" }
// ]}
```

## Tool Use

### Tool Definition

```swift
let toolDefinitions: [[String: Any]] = [
    [
        "name": "get_practice_catalog",
        "description": "Get available stress-relief practices...",
        "input_schema": [
            "type": "object",
            "properties": [:] as [String: Any]
        ]
    ],
    [
        "name": "suggest_practice",
        "description": "Recommend a specific practice...",
        "input_schema": [
            "type": "object",
            "properties": [
                "practice_id": ["type": "string", "description": "..."],
                "reason": ["type": "string", "description": "..."],
                "urgency": ["type": "string", "enum": ["low", "medium", "high"]]
            ],
            "required": ["practice_id", "reason", "urgency"]
        ]
    ]
]
```

### Tool Use Request

```swift
var body: [String: Any] = [
    "model": "claude-opus-4-6",
    "max_tokens": maxTokens,
    "system": toolUseSystemPrompt,
    "messages": messages,
    "tools": toolDefinitions
]
// + thinking block
body["thinking"] = ["type": "enabled", "budget_tokens": budget]
```

### Multi-Turn Tool Use Loop

```swift
// 1. Send request with tools
// 2. Parse response content blocks
// 3. If stop_reason == "tool_use":
//    a. Add assistant response to messages
//    b. Execute tool calls locally
//    c. Add tool_result blocks as user message
//    d. Send next request
// 4. If stop_reason == "end_turn" — parse final JSON

// Tool result format:
let toolResults: [[String: Any]] = [
    [
        "type": "tool_result",
        "tool_use_id": toolUseBlock.id,
        "content": resultJSON  // String
    ]
]
conversationMessages.append(["role": "user", "content": toolResults])
```

## Streaming (SSE)

```swift
// Enable streaming
requestBody["stream"] = true

// Parse SSE lines
let (bytes, response) = try await URLSession.shared.bytes(for: request)

for try await line in bytes.lines {
    guard line.hasPrefix("data: ") else { continue }
    let payload = String(line.dropFirst(6))
    if payload == "[DONE]" { break }

    guard let eventData = payload.data(using: .utf8),
          let event = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
          let eventType = event["type"] as? String else { continue }

    switch eventType {
    case "content_block_delta":
        let delta = event["delta"] as? [String: Any]
        let deltaType = delta?["type"] as? String

        switch deltaType {
        case "thinking_delta":
            let chunk = delta?["thinking"] as? String ?? ""
            accumulatedThinking += chunk
            onThinkingUpdate(accumulatedThinking)
        case "text_delta":
            let chunk = delta?["text"] as? String ?? ""
            accumulatedText += chunk
        default: break
        }
    case "error":
        let msg = (event["error"] as? [String: Any])?["message"] as? String
        throw ClaudeAPIError.invalidResponse(statusCode: 200, body: msg ?? "")
    default: break // ping, message_start, content_block_start, etc.
    }
}
```

## Response Parsing

````swift
// Claude wraps JSON in markdown code blocks sometimes
func extractJSON(from text: String) -> String {
    // Try ```json ... ```
    if let range = text.range(of: "```json"),
       let endRange = text.range(of: "```", range: range.upperBound..<text.endIndex) {
        return String(text[range.upperBound..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    // Try raw { ... }
    if let start = text.firstIndex(of: "{"),
       let end = text.lastIndex(of: "}") {
        return String(text[start...end])
    }
    return text
}
````

## Error Handling

```swift
enum ClaudeAPIError: Error, LocalizedError {
    case noAPIKey
    case networkError(underlying: Error)
    case invalidResponse(statusCode: Int, body: String)
    case decodingError(underlying: Error)
    case rateLimited          // 429
    case serverError(statusCode: Int)  // 500-599
    case dailyLimitReached    // Client-side limit
}

// Retry once on network error
do {
    result = try await performRequest(request)
} catch let error as ClaudeAPIError {
    if case .networkError = error {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        result = try await performRequest(request)
    }
    throw error
}
```

## Client Architecture

```swift
// Sendable struct — safe to pass across actors
struct ClaudeVisionClient: Sendable {
    enum Mode: Sendable {
        case direct(apiKey: String)
        case proxy(supabaseURL: String, anonKey: String, deviceID: String)
    }
    let mode: Mode
}

// API key sources (priority order):
// 1. Settings (user-entered)
// 2. Info.plist (ANTHROPIC_API_KEY)
// 3. Environment variable
// 4. Proxy mode (no key needed)
```

## Daily Limit

```swift
private static let maxDailyCalls = 100

// Track via UserDefaults
private func checkDailyLimit() throws {
    if currentDailyCount() >= Self.maxDailyCalls {
        throw ClaudeAPIError.dailyLimitReached
    }
}
```
