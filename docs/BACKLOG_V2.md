# Respiro Desktop — Backlog V2

> Hackathon: "Built with Opus 4.6" | Feb 10-16, 2026
> Full PRD: `docs/PRD.md` | Architecture: @Observable + actor Services
> V1 backlog (all done): `docs/BACKLOG.md`

---

## V1 Summary (ALL DONE)

P0 (10/10), P1 (11/11), P2 (7/7), D6.1-D6.2 done. See `BACKLOG.md`.
8 practices, weather monitoring, nudges, dismissal learning, day summary, demo mode.

---

## P3 — Opus 4.6 Showcase (Day 1)

| ID   | Task                                                                              | Est | Agent           | Depends | Status |
| ---- | --------------------------------------------------------------------------------- | --- | --------------- | ------- | ------ |
| P3.1 | Adaptive Thinking in ClaudeVisionClient — effort low/high/max per context         | 2h  | swift-developer | —       | done   |
| P3.2 | Tool Use for practice selection — define tools, parse tool_use blocks             | 3h  | swift-developer | P3.1    | done   |
| P3.3 | "Why This?" expandable reasoning panel on nudge card                              | 2h  | swiftui-pro     | P3.1    | done   |
| P3.4 | Wire nudge -> AI-suggested practice (pass suggested_practice_id to practice flow) | 1h  | swift-developer | —       | done   |

**P3 deliverable:** AI uses adaptive thinking + tool use. Judges see reasoning behind every suggestion.

---

## P4 — Demo Impact (Day 2)

| ID   | Task                                                                       | Est | Agent                         | Depends    | Status |
| ---- | -------------------------------------------------------------------------- | --- | ----------------------------- | ---------- | ------ |
| P4.1 | "The Silence Decision" — dashboard log when AI decides NOT to interrupt    | 3h  | swift-developer + swiftui-pro | P3.1       | done   |
| P4.2 | Streaming AI response with live thinking tokens in "Why This?" panel       | 4h  | swift-developer               | P3.1, P3.3 | done   |
| P4.3 | Keyboard shortcuts — Escape, Return, 1/2/3, Space (Cmd+Shift+R skipped)    | 2h  | swift-developer               | —          | done   |
| P4.4 | Effort level visualization — brain icon with 1-3 dots on nudge + dashboard | 2h  | swiftui-pro                   | P3.1       | done   |

**P4 deliverable:** "The Silence Decision" is our innovation angle. Live thinking + effort indicator = judges SEE Opus working.

---

## P5 — Visual + Content (Day 3)

| ID   | Task                                                                  | Est  | Agent           | Depends | Status |
| ---- | --------------------------------------------------------------------- | ---- | --------------- | ------- | ------ |
| P5.1 | Stress trajectory mini-graph (replace placeholder timeline dots)      | 3h   | swiftui-pro     | —       | done   |
| P5.2 | Timeline dots using real StressEntry data from SwiftData              | 1.5h | swift-developer | —       | done   |
| P5.3 | Port 12 practices from iOS (MockPracticeData.swift → PracticeCatalog) | 2h   | swift-developer | —       | done   |
| P5.4 | Science snippets on completion screen (8 JSON files from iOS)         | 1.5h | swift-developer | P5.3    | done   |
| P5.5 | Second Chance logic — suggest alternative when practice doesn't help  | 2h   | swift-developer | P5.3    | done   |

**P5 deliverable:** 20 practices, real data visualizations, science-backed snippets.

---

## P6 — Reliability + Polish (Day 4)

| ID   | Task                                                                     | Est | Agent           | Depends         | Status |
| ---- | ------------------------------------------------------------------------ | --- | --------------- | --------------- | ------ |
| P6.1 | Enhanced demo mode — showcase thinking, effort, tool use, silence        | 3h  | swift-developer | P3.1-P3.3, P4.1 | done   |
| P6.2 | Cross-platform "About" — iOS App Store link, ecosystem mention           | 1h  | swift-developer | —               | done   |
| P6.3 | Onboarding Screen Recording permission trigger (actual dialog, not text) | 1h  | swift-developer | —               | done   |
| P6.4 | Active hours enforcement in MonitoringService                            | 1h  | swift-developer | —               | done   |
| P6.5 | Wake-from-sleep detection (NSWorkspace notifications → immediate check)  | 1h  | swift-developer | —               | done   |

**P6 deliverable:** Demo mode covers full narrative. Edge cases fixed.

---

## P7 — Nice-to-Have

| ID   | Task                                                          | Est | Agent           | Status |
| ---- | ------------------------------------------------------------- | --- | --------------- | ------ |
| P7.1 | Sound design — subtle effects for nudge, practice, completion | 2h  | swift-developer | done   |
| P7.2 | Personalized tips from iOS (96 tips with conditions)          | 2h  | swift-developer | todo   |
| P7.3 | Adaptive Thinking in DaySummaryService (max effort)           | 1h  | swift-developer | done   |

---

## Demo Prep (Day 5)

| ID   | Task                           | Est | Agent  | Status |
| ---- | ------------------------------ | --- | ------ | ------ |
| D5.1 | Bug fixes + demo rehearsal     | 2h  | —      | todo   |
| D5.2 | Record backup demo video       | 1h  | manual | todo   |
| D5.3 | Write submission text + README | 1h  | manual | todo   |

---

## Sprint Plan

| Day | Focus            | Tasks                | Hours |
| --- | ---------------- | -------------------- | ----- |
| 1   | Opus Showcase    | P3.1-P3.4            | 8h    |
| 2   | Demo Impact      | P4.1-P4.4            | 11h   |
| 3   | Visual + Content | P5.1-P5.5            | 10h   |
| 4   | Polish           | P6.1-P6.5            | 7h    |
| 5   | Demo Prep        | P7 (cherry-pick), D5 | 6h    |

**Total: ~42h over 5 days**

---

## Key Decisions

1. **Adaptive Thinking = NON-NEGOTIABLE.** Hackathon = "Built with Opus 4.6." Without thinking/effort levels, judges ask "why not Sonnet?"
2. **"The Silence Decision" = innovation angle.** Every entry shows AI doing more. We show AI doing LESS. Keep Thinking Prize ($5,000) candidate.
3. **Show the Thinking.** Reasoning panel + effort indicator + streaming = judges SEE Opus working.
4. **Demo Mode = first-class feature.** 30% of score. Pre-scripted > live API.
5. **iOS cross-platform = credibility signal.** Don't build sync. Just mention "Live on iOS App Store."

---

## What NOT to Build

- Calendar integration (fake in demo if needed)
- Cloud sync / user accounts
- Social features
- Gamification (streaks, badges)
- Multiple monitor support

---

## iOS Code Reuse Map

| What                      | iOS Source                  | macOS Target            | Effort |
| ------------------------- | --------------------------- | ----------------------- | ------ |
| 12 practices (data)       | `MockPracticeData.swift`    | `PracticeCatalog.swift` | 1h     |
| Practice views (12 new)   | Reference only (TCA)        | New SwiftUI views       | 1h     |
| Science snippets (8 JSON) | `Resources/snippets_*.json` | `Resources/`            | 30min  |
| Science insights (8 JSON) | `Resources/insights_*.json` | `Resources/`            | 30min  |
| Second Chance logic       | `SecondChanceLogic.swift`   | New service             | 1h     |
| 96 personalized tips      | `TipRepository.swift`       | New service             | 2h     |
| Design tokens             | `RespiroColors/Typography`  | Theme files             | 1h     |

---

## Agent Specs — Adaptive Thinking (P3.1)

### API Format

```swift
// Add to ClaudeVisionClient request body:
"thinking": {
    "type": "enabled",
    "budget_tokens": budgetForEffort(effort)
}

func budgetForEffort(_ effort: EffortLevel) -> Int {
    switch effort {
    case .low:  return 1024    // routine checks, clear weather
    case .high: return 4096    // ambiguous situations, contradictory signals
    case .max:  return 10240   // end-of-day summary, complex reasoning
    }
}
```

### When to Use Each Effort

```
.low  — clear weather 3+ consecutive, no change, user idle
.high — stormy but user in flow, contradictory signals, first analysis after wake
.max  — DaySummaryService end-of-day reflection, "Silence Decision" reasoning
```

### maxTokens Note

Current `ClaudeVisionClient.swift` has `maxTokens = 1024` hardcoded. This must scale with effort:

- `.low`: 1024 (enough for JSON response)
- `.high`: 2048 (JSON + moderate thinking)
- `.max`: 4096 (day summary needs longer output)

### Response Parsing

```swift
// API response includes thinking blocks:
struct APIResponse: Codable {
    let content: [ContentBlock]  // includes thinking + text blocks
}

enum ContentBlock: Codable {
    case thinking(String)        // model's reasoning — display in "Why This?"
    case text(String)            // JSON response to parse
}
```

---

## Agent Specs — Tool Use (P3.2)

### Tool Definitions

```json
[
  {
    "name": "get_practice_catalog",
    "description": "Get available stress-relief practices with descriptions and durations",
    "input_schema": { "type": "object", "properties": {} }
  },
  {
    "name": "get_user_history",
    "description": "Get user's recent practice sessions, weather patterns, and preferences",
    "input_schema": {
      "type": "object",
      "properties": {
        "days": {
          "type": "integer",
          "description": "Number of days of history (default 7)"
        }
      }
    }
  },
  {
    "name": "suggest_practice",
    "description": "Recommend a specific practice to the user with reasoning",
    "input_schema": {
      "type": "object",
      "properties": {
        "practice_id": { "type": "string" },
        "reason": {
          "type": "string",
          "description": "Why this practice, in user-friendly language"
        },
        "urgency": { "type": "string", "enum": ["low", "medium", "high"] }
      },
      "required": ["practice_id", "reason", "urgency"]
    }
  }
]
```

### Context Split: Prompt vs Tools (avoid duplication!)

**In prompt (always, cheap):** Last 3 StressEntries, last nudge, dismissal count, time — immediate context for "here and now" decision.

**Via Tool Use (on demand, deep):** `get_user_history` for deeper queries — weekly patterns, practice success rates, category preferences. AI calls this tool only when prompt context isn't enough to decide.

This split avoids sending the same data twice (saves tokens).

### Tool Response Handling

AI calls `get_practice_catalog` → return practice list → AI reasons → calls `suggest_practice`.
Parse `tool_use` blocks from response. Extract `practice_id` and `reason` from `suggest_practice` call.
The interleaved thinking between tool calls IS the showcase — AI reasons about each result before next call.

---

## Agent Specs — "The Silence Decision" (P4.1)

### Data Model

```swift
struct SilenceDecision: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let thinkingText: String     // AI's reasoning for NOT interrupting
    let effortLevel: EffortLevel // usually .high (ambiguous signals)
    let detectedWeather: InnerWeather
    let signals: [String]
    let flowDuration: TimeInterval? // how long user has been in flow
}
```

### Dashboard UI

Add a "Recent Decision" card below the timeline:

```
+------------------------------------------+
|  brain.head.profile  Chose not to        |
|                      interrupt            |
|  "You've been in focused flow for        |
|   23 min. Stress: low."                  |
|                                          |
|  Effort: ●●○ HIGH    2 min ago           |
+------------------------------------------+
```

Fade in when new silence decision occurs. Show last decision only. Tap to expand full reasoning.

---

## Agent Specs — Effort Level Visualization (P4.4)

### Component

```
Low:    ●○○  "Quick check"
High:   ●●○  "Deep reasoning"
Max:    ●●●  "Full analysis"
```

SF Symbol: `brain.head.profile` with colored dots.

- Low: tertiary text color
- High: jade green
- Max: premium gold

Show on: NudgeView (next to AI message), DashboardView (in silence decision card), DaySummaryView (header).

---

## Agent Specs — Streaming (P4.2)

### Approach

Replace `URLSession.data(for:)` with `URLSession.bytes(for:)`.
Parse SSE lines (`data: {...}`). Extract thinking blocks progressively.
Feed thinking text to `ThinkingStreamView` which renders character-by-character with typing animation.

### Fallback

If streaming hits blockers, fallback: show thinking AFTER response completes (still valuable, just not real-time). The "Why This?" panel shows the same content either way.
