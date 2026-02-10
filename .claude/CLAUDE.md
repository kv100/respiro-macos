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
├── RespiroDesktopApp.swift          # @main, MenuBarExtra
├── Core/
│   ├── AppState.swift               # @MainActor @Observable, Screen enum
│   ├── ScreenMonitor.swift          # ScreenCaptureKit, timer (actor)
│   ├── ClaudeVisionClient.swift     # Opus 4.6 API (Sendable struct)
│   ├── NudgeEngine.swift            # Cooldowns, suppression (actor)
│   └── PracticeManager.swift        # Practice flow, timer (@Observable)
├── Models/                          # SwiftData + enums
├── Views/                           # MenuBar/, Onboarding/, Nudge/, Practice/, Settings/
├── Practices/                       # PracticeCatalog.swift
└── Resources/
    └── Assets.xcassets
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
- NO server/backend — local + Claude API
- NO localization — English only for hackathon
- NO UIKit — macOS only (NSImage, NSScreen, etc.)
- Screenshots NEVER written to disk
- Claude API key: `ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]`

---

## Session Start

1. Read this file (auto-loaded)
2. Read `docs/BACKLOG.md` for current tasks and specs
3. Start working
