# Quality Gates

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI (MenuBarExtra with `.window` style)
- **Architecture:** @Observable + actor Services (NO TCA)
- **Persistence:** SwiftData (local only)
- **Screenshots:** ScreenCaptureKit (SCScreenshotManager)
- **AI:** Claude Opus 4.6 Vision API (NEVER GPT, NEVER Sonnet in production)
- **macOS Target:** 14+ (Sonoma)
- **Concurrency:** async/await, actors, Sendable
- **Dependencies:** Zero — Apple frameworks only

## Post-Implementation Checks

- `swift build` passes (or `xcodebuild build`)
- No GPT references (only Claude Opus 4.6)
- No force unwraps (!) without justification
- Sendable conformance for shared types
- No iOS-only APIs (UIKit, UIImage, etc.)
- No data written to disk from screenshots
- API key from environment, not hardcoded
- No security vulnerabilities

## Post-Agent Verification

After each agent output:

1. **Build:** `swift build` or `xcodebuild -scheme RespiroDesktop build`
2. **Diff:** `git diff --stat`
3. **Integration:** new code integrates with existing services/models
4. **Specs match:** verify against `docs/BACKLOG.md` Agent Specs

## Critical Rules

- Delegate to agents, don't do work yourself
- Ask user for architectural decisions
- Speed > perfection — hackathon rules
- Every feature must contribute to 3-min demo
- Agents read `docs/BACKLOG.md`, NOT the full PRD

## Swift 6 Concurrency

- All shared types must be Sendable
- Use actors for shared mutable state (MonitoringService, NudgeEngine)
- Use @MainActor @Observable for UI state (AppState, PracticeManager)
- Use Sendable struct for stateless services (ClaudeVisionClient)
- Use async/await (not completion handlers)
- No data races allowed
