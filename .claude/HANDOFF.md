# Handoff — Context for New Claude Code Session

> **Use this file to quickly onboard a new Claude Code session with current project state.**

---

## Current Status (Feb 13, 2026)

**Project:** Respiro macOS — AI stress coach for "Built with Opus 4.6" hackathon
**Deadline:** Feb 16, 3PM EST (3 days remaining)
**Status:** V1 + V2 + POST-V2 COMPLETE ✅

---

## What's Done

### V1 COMPLETE (P0-P2)

- Core monitoring loop (ScreenCaptureKit → Opus 4.6 Vision → Weather)
- NudgeEngine (cooldowns, suppressions, silence decisions)
- 20 practices with completion flow
- SwiftData persistence
- Demo mode (8 scenarios)

### V2 COMPLETE (P3-P7)

- Second Chance (alternative practice)
- Day Summary (max thinking, 1M context)
- Sound design
- Keyboard shortcuts
- 96 contextual tips
- Active hours + wake detection

### POST-V2 POLISH (Feb 12-13)

✅ **Multi-monitor support** — captures ALL displays, side-by-side montage
✅ **Menu bar context menu** — NSStatusItem with right-click (Start/Pause/Quit)
✅ **Demo mode cleanup** — clearDemoData() on disable
✅ **UI polish** — hidden scrollbars
✅ **Keychain optimization** — fewer password prompts

**See:** `docs/POST_V2_UPDATES.md` for full technical details

---

## Architecture Decisions

### Multi-Monitor Support

**File:** `RespiroDesktop/Core/ScreenMonitor.swift`

- Captures ALL displays from `content.displays` (not just `.first`)
- `createSideBySideMontage()` method for horizontal concatenation
- Scales each display proportionally to fit 1568px total
- Single API call with full workspace context

### Menu Bar Controller

**Files:**

- `RespiroDesktop/Core/MenuBarController.swift`
- `RespiroDesktop/Core/AppDelegate.swift`
- Updated: `RespiroDesktop/RespiroDesktopApp.swift`

**Why:** SwiftUI MenuBarExtra doesn't support right-click menus
**Solution:** NSStatusItem with manual popover management

- Left click → NSPopover with MainView
- Right click → NSMenu with quick actions
- `withObservationTracking` for reactive icon updates

### Demo Mode Data

**Files:**

- `RespiroDesktop/Core/DemoModeService.swift`
- `RespiroDesktop/Core/AppState.swift`

**Change:** Added `clearDemoData(modelContext:)` to remove test data on disable
**Why:** Demo data persisted after toggling off

---

## Key Files & Locations

### Core Services (actors + @Observable)

```
RespiroDesktop/Core/
├── AppDelegate.swift           # NSApplicationDelegate, monitoring setup
├── MenuBarController.swift     # NSStatusItem, left/right click, popover
├── AppState.swift              # @MainActor @Observable, navigation
├── ScreenMonitor.swift         # Multi-display capture + montage
├── MonitoringService.swift     # Screenshot loop, adaptive timer
├── ClaudeVisionClient.swift    # Opus 4.6 Vision + Tool Use + Streaming
├── NudgeEngine.swift           # Cooldowns, suppression, silence
├── DemoModeService.swift       # 8 scenarios + clearDemoData
├── DaySummaryService.swift     # End-of-day reflection (max thinking)
└── [other services...]
```

### Views

```
RespiroDesktop/Views/
├── MainView.swift              # Screen router
├── MenuBar/DashboardView.swift # Graph, silence card, tips (hidden scrollbar)
├── Nudge/NudgeView.swift       # Nudge cards, thinking panel
├── Practice/                   # 10 practice views + completion
├── Settings/SettingsView.swift # Preferences, demo toggle
└── [other views...]
```

### Documentation

```
docs/
├── POST_V2_UPDATES.md          # ← READ THIS for recent changes
├── BACKLOG.md                  # V1 tasks
├── BACKLOG_V2.md               # V2 tasks
├── BACKLOG_PLAYTEST.md         # Playtest system (foundation only)
└── PRD.md                      # Full PRD (reference only)
```

---

## Important Conventions

### Swift 6 Concurrency

- All shared types must be `Sendable`
- Use `actor` for shared mutable state
- Use `@MainActor @Observable` for UI state
- Use `Sendable struct` for stateless services

### Code Style

- Speed > perfection (hackathon)
- NO TCA, NO ObservableObject
- SwiftUI only (no UIKit)
- Zero dependencies (Apple frameworks only)
- Screenshots NEVER to disk (memory only)

### Git Workflow

- Always use descriptive commit messages
- Include `Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>`
- Never force-push to main
- Never skip pre-commit hooks without user approval

---

## What's NOT Done (Post-Hackathon)

- ❌ Backend proxy (Supabase Edge Function)
- ❌ Playtest system (PT.1-PT.9) — foundation exists, not activated
- ❌ Demo video (D5.2)
- ❌ Submission text (D5.3)

---

## Common Tasks & Patterns

### Adding a new Core service

1. Create `RespiroDesktop/Core/ServiceName.swift`
2. Choose isolation: `actor` (mutable) or `Sendable struct` (stateless) or `@Observable` (UI)
3. Wire in `AppDelegate.swift` or `AppState.swift`
4. Update `.claude/CLAUDE.md` Project Structure

### Modifying ScreenMonitor

- File: `RespiroDesktop/Core/ScreenMonitor.swift`
- Multi-display logic in `captureScreenshot()` (lines 47-106)
- Montage logic in `createSideBySideMontage()` (lines 123-168)
- Don't break `maxLongEdge = 1568` constraint (API limit)

### Updating Demo Mode

- File: `RespiroDesktop/Core/DemoModeService.swift`
- 8 scenarios defined in `demoScenario` array (lines 44-183)
- Seed data in `seedDemoData()` (lines 207-278)
- Clear data in `clearDemoData()` (lines 280-311)

---

## Quick Debugging

### Build fails

```bash
xcodebuild -scheme RespiroDesktop build 2>&1 | grep "error:"
```

### SourceKit errors (usually false)

- Ignore SourceKit LSP errors
- Trust `xcodebuild build` output

### Keychain password prompts

- Expected with ad-hoc signing
- Added `kSecAttrAccessible` to reduce frequency
- Can't eliminate without development certificate

---

## For Next Session

### If continuing implementation:

1. Read `docs/POST_V2_UPDATES.md` for context
2. Check git log: `git log --oneline -10`
3. Run build: `xcodebuild -scheme RespiroDesktop build`
4. All POST-V2 features are DONE and tested

### If recording demo:

1. Test on real 2+ monitor setup
2. Toggle demo mode on/off to verify cleanup
3. Show right-click context menu
4. Highlight multi-monitor montage in thinking panel

### If writing submission:

1. Emphasize multi-monitor support (real-world impact)
2. Reference `docs/POST_V2_UPDATES.md` for technical depth
3. Opus 4.6 showcase: Vision + Thinking + Tool Use + 1M context
4. Demo quality matters (30% of judging)

---

## Questions to Ask User

Before starting work:

- "What needs to be done?" (avoid assumptions)
- "Is this for the demo video or post-submission?" (prioritization)
- "Should I continue from where the last session left off?" (continuity)

---

## Key Insights (Learned During Development)

### Multi-Monitor Discovery

- Original code used `content.displays.first` — missed 2nd+ screens
- Real users work across multiple monitors simultaneously
- Missing Slack/terminal context = failed stress detection
- Solution: capture ALL displays, montage side-by-side

### Menu Bar UX

- MenuBarExtra `.window` doesn't support right-click
- Users expect native macOS menu bar behavior
- NSStatusItem gives full control (left/right click)
- Popover + NSMenu = professional UX

### Demo Mode Data Pollution

- seedDemoData() added 8 StressEntry + 2 PracticeSession
- Toggling off left stale data on dashboard
- Users confused by old test data
- clearDemoData() fixed clean toggle

### Keychain + Ad-Hoc Signing

- Every build = new signature = new password prompt
- Can't use `keychain-access-groups` without dev cert
- `kSecAttrAccessible` reduces frequency
- Acceptable for hackathon, fix post-submission

---

## Current Git State

```bash
# Last commits
f4af895 docs: update README with post-V2 features
3e7c97e feat: post-V2 polish - multi-monitor + menu bar + UX improvements
1e453a0 feat: playtest infrastructure + virtual time in NudgeEngine
```

All changes committed and pushed. Working tree clean.

---

## How to Use This File

**Starting a new Claude Code session:**

1. Open project in Claude Code
2. Say: "Read `.claude/HANDOFF.md` to understand current state"
3. Claude will load context and be ready to continue

**Updating this file:**

- Add new decisions to "Architecture Decisions"
- Update "Current Status" when completing major milestones
- Add learnings to "Key Insights"

---

**Last Updated:** Feb 13, 2026 (POST-V2 POLISH complete)
**Next Milestone:** Demo video + submission text
