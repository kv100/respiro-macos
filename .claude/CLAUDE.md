# Claude Code Rules for Respiro macOS

## Project Context

**Hackathon:** "Built with Opus 4.6" — Anthropic Claude Code Hackathon (Feb 10-16, 2026)
**Rules:** New project from scratch, open source, solo, 3-min demo video + GitHub repo due Feb 16 3PM EST
**Judging:** Impact 25%, Opus 4.6 Use 25%, Depth & Execution 20%, Demo 30%

## Language

- **Documents:** English
- **Chat:** Russian

---

@import rules/01-orchestrator.md
@import rules/02-quality-gates.md

---

## What We're Building

**macOS Menu Bar AI Stress Coach** — an app that:

1. Lives in the menu bar as SF Symbol weather icon (sun/cloud/storm)
2. Takes periodic screenshots via ScreenCaptureKit (memory only, never disk)
3. Sends screenshot to Claude Opus 4.6 Vision API for stress analysis
4. Returns weather metaphor (clear/cloudy/stormy) + nudge decision
5. Offers guided micro-practices (breathing, grounding, mindfulness) in a popup
6. Learns from dismissals and feedback — AI adapts over time

### Key Differentiator

**"AI that stays quiet"** — the hardest AI problem is knowing WHEN to help. Respiro uses Opus 4.6 to decide when NOT to interrupt.

### Opus 4.6 Showcase (25% of judging!)

- **Vision API** — screenshot stress analysis (multimodal)
- **Adaptive Thinking** — deep reasoning about whether to interrupt vs. stay silent
- **Tool Use** — practice selection from user history
- **1M Context Window** — end-of-day reflection with full day context

---

## Documents (READ THIS FIRST!)

| Document              | What                                                 | When to read                    |
| --------------------- | ---------------------------------------------------- | ------------------------------- |
| **`docs/BACKLOG.md`** | Tasks + Agent Specs (UI, models, prompts, cooldowns) | **ALWAYS before coding**        |
| `docs/PRD.md`         | Full PRD (strategy, flows, edge cases)               | Only for "why" behind decisions |

**CRITICAL:** `docs/BACKLOG.md` is the single source of truth for agents. It contains:

- Task list with dependencies (P0-P2 + Day 6)
- Project structure (file → directory mapping)
- All data models (SwiftData, enums, API response) — copy-paste ready
- AI prompts (system + per-screenshot templates)
- UI specs (colors, sizes, animations, SF Symbols)
- Cooldown/interval constants
- Practice catalog with phase patterns
- Edge case handling

**Agents: read `docs/BACKLOG.md` before writing any code. Do NOT read the 1100-line PRD unless you need strategic context.**

---

## Tech Stack

- **Language:** Swift 6 (strict concurrency)
- **UI:** SwiftUI (MenuBarExtra with `.window` style)
- **Architecture:** @Observable + actor Services (NO TCA, NO ObservableObject)
- **Persistence:** SwiftData (local only, no cloud)
- **Screenshots:** ScreenCaptureKit (SCScreenshotManager)
- **AI:** Claude Opus 4.6 API (Vision + Text) via URLSession
- **Target:** macOS 14+ (Sonoma)
- **Dependencies:** Zero — only Apple frameworks

---

## Project Structure

```
RespiroDesktop/
├── RespiroDesktopApp.swift          # @main, AppDelegate wiring
├── Core/
│   ├── AppDelegate.swift            # NSApplicationDelegate, MenuBarController init, monitoring setup
│   ├── MenuBarController.swift      # NSStatusItem, left/right click handling, popover management
│   ├── AppState.swift               # @MainActor @Observable, Screen enum, central state
│   ├── ScreenMonitor.swift          # ScreenCaptureKit, multi-display capture + montage (actor)
│   ├── ClaudeVisionClient.swift     # Opus 4.6 Vision + Tool Use + Streaming (Sendable struct)
│   ├── MonitoringService.swift      # Adaptive timer, screenshot loop (actor)
│   ├── NudgeEngine.swift            # Cooldowns, suppression, NudgeDecision (actor)
│   ├── PracticeManager.swift        # Practice flow, breathing timer (@Observable)
│   ├── DemoModeService.swift        # 8 pre-scripted scenarios + clearDemoData (@Observable)
│   ├── DaySummaryService.swift      # End-of-day reflection with max thinking (actor)
│   ├── SecondChanceService.swift    # Alternative practice from different category
│   ├── SoundService.swift           # System sounds for nudge/practice/completion
│   └── TipService.swift             # 96 contextual wellness tips
├── Models/                          # SwiftData (StressEntry, PracticeSession, etc.) + enums
├── Views/
│   ├── MainView.swift               # Screen router with keyboard shortcuts
│   ├── MenuBar/DashboardView.swift  # Graph, silence card, tip card, controls (hidden scrollbar)
│   ├── Nudge/NudgeView.swift        # Nudge cards, thinking panel, tool use display
│   ├── Practice/                    # 10 practice views + completion + weather picker
│   ├── Components/                  # EffortIndicatorView, StressGraphView, ThinkingStreamView
│   ├── Settings/SettingsView.swift  # Preferences, about, demo toggle
│   ├── Summary/DaySummaryView.swift # Day reflection with thinking panel
│   └── Onboarding/                  # Welcome + screen recording permission
├── Practices/PracticeCatalog.swift  # 20 practices (breathing, body, mind)
└── Resources/Assets.xcassets
```

---

## Conventions

- Speed > perfection — working demo > clean code
- Every feature must contribute to the 3-minute demo
- Privacy-first: screenshots in memory only, deleted after API call
- Heritage Jade dark theme: background `#0A1F1A`, accent `#10B981`
- SF Symbol weather icons in menu bar (sun.max / cloud / cloud.bolt.rain)
- Always dark mode (`.preferredColorScheme(.dark)`)
- API key embedded via env var or plist — zero setup for user

## Guardrails

- NO TCA — use @Observable + actor Services
- NO Metal shaders — SwiftUI animations only
- NO localization — English only for hackathon
- NO UIKit — macOS only (NSImage, NSScreen, etc.)
- Screenshots NEVER written to disk
- Claude API key: `ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]`
- Don't misattribute internal CLAUDE.md rules as external hackathon rules — always cite the actual source accurately

---

## Project Status

**V1 COMPLETE:** P0 (10/10), P1 (11/11), P2 (7/7), D6.1-D6.2
**V2 COMPLETE:** P3 (4/4), P4 (4/4), P5 (5/5), P6 (5/5), P7 (3/3)
**D5.1 DONE:** 19 bugs found and fixed across 3 rounds of verification. All 8 demo scenarios pass.
**POST-V2 POLISH (Feb 12-13):**

- ✅ Multi-monitor support (capture all displays, side-by-side montage)
- ✅ Menu bar context menu (right-click: Start/Pause/Quit via NSStatusItem)
- ✅ Demo mode cleanup (clearDemoData when disabled)
- ✅ UI polish (hidden scrollbars on Dashboard)
- ✅ Keychain optimization (reduced password prompts)
  **See:** `docs/POST_V2_UPDATES.md` for full details
  **Remaining:** D5.2 (demo video), D5.3 (submission text)

---

## Post-Hackathon Roadmap: Backend Proxy

**Current (hackathon):** BYOK (Bring Your Own Key) — API key via env var. Demo mode works without key.

**Next (post-hackathon):** Backend proxy so users never see an API key.

Architecture:

```
App → Supabase Edge Function (our API key) → Claude API
```

Implementation plan:

1. Supabase Edge Function (~50 lines) as proxy to Claude API
2. Supabase Auth (Apple Sign-In) for user authentication
3. Rate limiting per user (prevent abuse)
4. Remove BYOK from app, add auth flow
5. Monetization: freemium (5 analyses/day free, unlimited = subscription)

This adds no hackathon value (judges evaluate the app, not the business model), but is required for App Store / production distribution.

---

## Session Start

1. Read this file (auto-loaded)
2. Read `docs/BACKLOG_V2.md` for current status
3. Start working
