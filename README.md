# Respiro Desktop

> **AI-powered macOS stress coach** | Built with Claude Opus 4.6 | Anthropic Hackathon Feb 2026

<p align="center">
  <img src="docs/assets/respiro-icon.png" alt="Respiro" width="128" />
</p>

## The Problem

Knowledge workers spend 8+ hours staring at screens, unaware of mounting stress until it's too late. Existing wellness apps require manual check-ins — by then, the damage is done.

## The Solution

Respiro lives in your macOS menu bar as a weather icon. It periodically captures screenshots (memory only, never disk), sends them to **Claude Opus 4.6 Vision API** for stress analysis, and represents your inner state as weather: clear, cloudy, or stormy.

**The hardest AI problem is knowing when NOT to help.** Respiro uses Opus 4.6's adaptive reasoning to decide when to stay quiet — and shows you its thinking when it does.

## How Opus 4.6 Powers Respiro

### Vision API — Multimodal Stress Detection

Screenshots are analyzed by Opus 4.6 to detect visual stress cues: tab count, notification volume, app switching frequency, error messages, video call fatigue. The AI never reads message content or names.

### Adaptive Thinking (Extended Thinking)

Every analysis uses effort-scaled thinking budgets:

- **Low** (1K tokens): Routine clear-weather checks
- **High** (4K tokens): Ambiguous signals, contradictory cues
- **Max** (10K tokens): End-of-day reflection with full context

### Tool Use — Practice Selection

When stress is detected, Opus 4.6 calls tools to select the best practice:

1. `get_practice_catalog` — reviews 20 available practices
2. `get_user_history` — checks what worked before
3. `suggest_practice` — makes a reasoned recommendation

The interleaved thinking between tool calls IS the showcase — the AI reasons about each result before the next call.

### "The Silence Decision" — AI That Stays Quiet

The innovation angle: when Opus detects stress but determines the user is in productive flow, it **chooses not to interrupt** and logs its reasoning. Users see exactly when and why the AI stayed quiet. This is the hardest AI problem — restraint.

### Streaming Thinking

The "Why This?" panel shows Opus 4.6's reasoning in real-time with a typing animation, making the AI's thought process visible and transparent.

### 1M Context — Day Reflection

End-of-day summary uses `.max` effort (10K thinking tokens) to reflect on the full day of stress entries, practices, and dismissals — producing personalized insights.

## Features

- **Weather-based stress visualization** — clear/cloudy/stormy in menu bar
- **Stress trajectory graph** — smooth bezier curve showing your day
- **20 evidence-based practices** — breathing, body, and mind techniques
- **Smart nudge system** — cooldowns, daily limits, dismissal learning
- **"The Silence Decision"** — visible AI restraint on dashboard
- **Tool Use showcase** — AI tool calls displayed in nudge card
- **Effort level indicator** — brain icon shows AI thinking depth (1-3 dots)
- **Practice reason** — personalized "why this practice" explanation
- **96 contextual wellness tips** — condition-based filtering by weather/time
- **Category-specific science snippets** — 21 research-backed facts
- **Second Chance** — suggests alternative practice from different category
- **Adaptive screenshot intervals** — faster when stormy, slower when clear
- **Sound design** — subtle system sounds for key moments
- **Keyboard shortcuts** — Return, Escape, Space, 1/2/3 for quick navigation
- **Demo mode** — 8 pre-scripted scenarios showcasing all Opus features
- **Active hours** — respects your work schedule
- **Wake-from-sleep** — immediate check after returning

## Tech Stack

| Layer        | Technology                             |
| ------------ | -------------------------------------- |
| Language     | Swift 6 (strict concurrency)           |
| UI           | SwiftUI (MenuBarExtra `.window` style) |
| Architecture | @Observable + actor Services           |
| AI           | Claude Opus 4.6 Vision + Text + Tools  |
| Screenshots  | ScreenCaptureKit (memory only)         |
| Persistence  | SwiftData (local only)                 |
| Target       | macOS 14+ (Sonoma)                     |
| Dependencies | Zero — Apple frameworks only           |

## Architecture

```
AppState (@MainActor @Observable)        — Central state, navigation, SwiftData persistence
MonitoringService (actor)                — ScreenCaptureKit + adaptive timer + tool context
ClaudeVisionClient (Sendable struct)     — Vision API + Tool Use + Streaming (SSE)
NudgeEngine (actor)                      — Cooldowns, suppression, silence decisions
DaySummaryService (actor)                — End-of-day reflection with max thinking
DemoModeService (@Observable)            — 8 pre-scripted scenarios, all Opus features
SecondChanceService (Sendable struct)    — Alternative practice from different category
TipService (Sendable struct)             — 96 contextual wellness tips
SoundService (@MainActor)               — Subtle system sound effects
```

## Building

```bash
# Build
xcodebuild -scheme RespiroDesktop -destination 'platform=macOS' build

# Run (set API key)
export ANTHROPIC_API_KEY="sk-ant-..."
open build/Release/RespiroDesktop.app
```

Or open `RespiroDesktop.xcodeproj` in Xcode and run.

**Demo mode** works without an API key — toggle in Settings.

## Privacy

- Screenshots captured in memory only — **never written to disk**
- All data stays local (SwiftData, no cloud sync)
- Claude API analyzes visual stress cues, never reads message content or names
- API key stored locally, never transmitted to third parties
- Menu bar only (LSUIElement) — no dock icon

## Cross-Platform

Respiro is also available on iOS (App Store). The macOS version is a standalone native app built specifically for the desktop experience.

## Roadmap

- **Backend proxy** — Supabase Edge Function so users don't need their own API key
- **Apple Sign-In** — authentication for production distribution
- **iCloud sync** — stress data across Mac and iOS
- **Calendar integration** — meeting context for smarter nudge timing
- **Watch companion** — heart rate data for biometric stress signals

## License

MIT

---

Built with [Claude Code](https://claude.ai/claude-code) for the Anthropic **"Built with Opus 4.6"** Hackathon (Feb 10-16, 2026)
