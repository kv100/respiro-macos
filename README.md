# Respiro Desktop

> AI-powered macOS stress coach for the "Built with Opus 4.6" Hackathon (Feb 10-16, 2026)

## What is Respiro?

Respiro is a macOS menu bar app that uses Claude Opus 4.6 Vision API to analyze your desktop stress level through periodic screenshots. It visualizes your inner state as weather (clear/cloudy/stormy) and offers gentle, timely nudges to practice evidence-based stress relief techniques.

**The hardest AI problem**: knowing when NOT to interrupt. Respiro uses Opus 4.6's adaptive reasoning to decide when to stay quiet.

## Tech Stack

- **Language:** Swift 6 (strict concurrency)
- **UI:** SwiftUI (MenuBarExtra with `.window` style)
- **Architecture:** @Observable + actor Services
- **AI:** Claude Opus 4.6 Vision API
- **Screenshots:** ScreenCaptureKit (memory only, never disk)
- **Persistence:** SwiftData (local only)
- **Target:** macOS 14+ (Sonoma)
- **Dependencies:** Zero - Apple frameworks only

## Project Status

### P0 - Foundation (COMPLETED)

- ✅ P0.1: Xcode project, MenuBarExtra, AppState, folder structure

### Next Steps

- P0.2: SF Symbol weather icons with transitions
- P0.3: ScreenCaptureKit screenshot capture
- P0.4: Claude Vision API client
- P0.5: Monitoring service with adaptive intervals
- P0.6: Nudge engine with cooldowns
- P0.7: Nudge popup UI
- P0.8: Physiological Sigh practice
- P0.9: SwiftData models

## Building

```bash
xcodebuild -scheme RespiroDesktop -destination 'platform=macOS' build
```

## Privacy

- Screenshots captured in memory only, never written to disk
- No server storage - all data stays local
- Claude API analyzes visual stress cues, never reads message content
- LSUIElement = true (no dock icon, menu bar only)

## Architecture

```
AppState (@MainActor @Observable)     — Central state, navigation
MonitoringService (actor)             — ScreenCaptureKit + timer
ClaudeVisionClient (Sendable struct)  — Opus 4.6 Vision API
NudgeEngine (actor)                   — Cooldowns, learning
PracticeManager (@MainActor @Observable) — Practice flow, timer
```

## License

MIT (hackathon submission)

---

Built with Claude Code for the Anthropic "Built with Opus 4.6" Hackathon
