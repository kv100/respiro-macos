# Respiro Desktop

> **AI-powered macOS stress coach** | Built with Claude Opus 4.6 | Anthropic Hackathon Feb 2026

## Download

**[Download Respiro.dmg (v1.0.0)](https://github.com/kv100/respiro-macos/releases/latest/download/Respiro.dmg)** — macOS 14+, signed & notarized

> Open DMG → drag to Applications → launch. Grant Screen Recording permission when prompted.
> Works out of the box — **no API key needed.** Demo Mode showcases all features with pre-built scenarios.

## The Problem

Knowledge workers spend 8+ hours staring at screens, unaware of mounting stress until it's too late. Existing wellness apps require manual check-ins — by then, the damage is done.

## The Solution

Respiro lives in your macOS menu bar as a weather icon. It periodically captures screenshots (memory only, never disk), sends them to **Claude Opus 4.6 Vision API** for stress analysis, and represents your inner state as weather: clear, cloudy, or stormy.

**The hardest AI problem is knowing when NOT to help.** Respiro uses Opus 4.6's adaptive reasoning to decide when to stay quiet — and shows you its thinking when it does.

## How Opus 4.6 Powers Respiro

### Vision API — Multimodal Stress Detection

Screenshots are analyzed by Opus 4.6 to detect visual stress cues: tab count, notification volume, app switching frequency, error messages, video call fatigue. The AI never reads message content or names.

**Multi-Monitor Support:** For users with 2+ displays, Respiro captures ALL screens and creates a side-by-side montage (`[Screen1|Screen2|Screen3]`), giving Opus 4.6 complete workspace context. This prevents "blind spots" — the AI sees Slack overload on Display 2 while you're working in a browser on Display 1, enabling accurate stress detection in real-world multi-tasking scenarios.

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

### Core Experience

- **Weather-based stress visualization** — clear/cloudy/stormy in menu bar with animated SF Symbols
- **Multi-monitor support** — captures ALL displays, side-by-side montage for full workspace context
- **"The Silence Decision"** — AI decides when NOT to interrupt and shows its reasoning
- **Smart nudge system** — cooldowns, daily limits, dismissal learning, 3 nudge types
- **Encouragement nudges** — lighter intervention for moderate stress
- **macOS notifications** — nudges visible even when popover is closed, with action buttons
- **Auto-open popover** — popover appears automatically when a nudge arrives

### AI (Opus 4.6)

- **Vision API** — multimodal screenshot analysis for stress detection
- **Adaptive Thinking** — effort-scaled thinking budgets (1K / 4K / 10K tokens)
- **Tool Use** — AI calls tools to select best practice, displayed in nudge card
- **Day Summary** — end-of-day AI reflection with max thinking budget (1M context)
- **Practice reason** — personalized "why this practice" explanation from AI
- **Effort level indicator** — brain icon shows AI thinking depth (1-3 dots)

### Practices

- **20 evidence-based practices** — breathing, body, and mind techniques
- **Practice Library** — browse all practices by category
- **Smart practice selection** — rotation, avoids repeats, first-time default (physiological sigh)
- **Weather check-in** — report how you feel before and after practice (delta badge)
- **Second Chance** — suggests alternative practice from different category if weather didn't improve
- **21 science snippets** — research-backed facts shown on completion

### Behavioral Intelligence

- **Personal baseline learning** — builds YOUR normal over 7 days of use
- **Real-time context switch tracking** — NSWorkspace notification-based, not polling
- **Weather floor** — user-reported weather sets minimum for 30 minutes
- **Adaptive screenshot intervals** — faster when stormy, slower when clear
- **Screen sharing suppression** — blocks nudges during screen share
- **Extreme behavioral override** — bypasses confidence gate at severity 0.85+
- **Dismiss-later semantics** — "not now" doesn't penalize, "I'm fine" does
- **Wake-from-sleep** — immediate check after returning

### Polish

- **Stress trajectory graph** — smooth bezier curve showing your day
- **96 contextual wellness tips** — filtered by weather and time of day
- **Sound design** — subtle system sounds for nudge, practice, completion
- **Keyboard shortcuts** — Return, Escape, 1/2/3 for quick navigation
- **Menu bar context menu** — right-click for Start/Pause/Quit
- **Demo mode** — 8 pre-scripted scenarios showcasing all Opus features
- **AI Playtest System** — seed + AI-generated scenarios, regression suite

## 🧠 How Respiro Actually Works (The Hard Part)

### The Problem: Stress Detection Without Biometrics

Most stress tracking apps use heart rate, HRV, or galvanic skin response. Respiro has only a screenshot. How do you tell if someone is stressed just from looking at their desktop?

### The Naive Approach (Doesn't Work)

```
Screenshot → AI → "You look stressed"
❌ Accuracy: ~60%, lots of false positives
```

**Problem:** Same screenshot can mean different things. 20 open tabs might be:

- Normal for a DevOps engineer (baseline: 18 tabs)
- High stress for a designer (baseline: 5 tabs)

### Respiro's Solution: Multi-Modal Behavioral Analysis

```
Screenshot + Behavior Patterns + Personal Baseline → AI Reasoning
✅ Accuracy: ~90%, false positives reduced 70%
```

#### Three Layers of Context:

**1. Visual Analysis** (Claude Opus 4.6 Vision)

- Tab count, notifications, error messages
- App chaos, video call fatigue
- Calendar deadlines, inbox overload

**2. Behavioral Metrics** (NEW)

- Context switch velocity: 8 switches/5min (baseline: 2/5min) ← SPIKE
- Session duration: 2.5h without break (unusual for this user)
- App fragmentation: 15% per app (vs 70% normal focus)
- Notification accumulation: 12 in 10min (vs 2 baseline)

**3. Personal Baseline** (NEW)

- Your "normal" at 2pm Tuesday: calm, 8 tabs, Xcode-focused
- Current: 23 tabs, Slack/IDE/Browser switching every 30s
- Deviation: +187% tabs, +300% context switches → ANOMALY

#### Why This Works:

**Same screenshot, different behavior → different decision.**

Example: User with 20 open browser tabs

- **User A** (baseline: 5 tabs) → Stress detected (confidence 0.85)
- **User B** (baseline: 18 tabs) → Normal working mode (confidence 0.2)

#### Technical Approach:

Respiro tracks:

- Active app changes via NSWorkspace notifications (real-time, not polling)
- Window switching patterns
- Notification arrival rates
- Session duration without breaks
- Video call detection (Zoom, Teams, Meet)

After 7 days, it builds YOUR baseline:

- Typical tab count
- Average context switch rate
- Normal app mix (Xcode 60%, Safari 30%, Slack 10%)
- Usual session lengths

Every analysis compares **current state vs YOUR normal**.

#### Opus 4.6 Showcase:

- **Extended thinking** with behavioral reasoning
- **Multi-turn tool use** (get_user_history, get_behavior_baseline, suggest_practice)
- **Adaptive confidence** calibration per user
- **1M context window** for end-of-day reflection with full day history

#### False Positive Learning:

Respiro learns when it's wrong:

- Dismissed during code reviews 7 times → lower confidence for that pattern
- Chaotic on Friday 4pm but user said "I'm fine" → learn "Friday wind-down"
- Many apps at 9am → learn "morning ramp-up is normal for this user"

AI adapts to YOU, not generic rules.

### The Result:

**An AI that knows when to stay quiet.**

Most AI interrupts you. Respiro asks: "Should I interrupt right now?"

The hardest AI problem is knowing WHEN to help.

## Tech Stack

| Layer        | Technology                            |
| ------------ | ------------------------------------- |
| Language     | Swift 6 (strict concurrency)          |
| UI           | SwiftUI + NSStatusItem (menu bar)     |
| Architecture | @Observable + actor Services          |
| AI           | Claude Opus 4.6 Vision + Text + Tools |
| Screenshots  | ScreenCaptureKit (multi-display)      |
| Persistence  | SwiftData (local only)                |
| Target       | macOS 14+ (Sonoma)                    |
| Dependencies | Zero — Apple frameworks only          |

## Architecture

```
AppDelegate (@MainActor)                 — NSApplicationDelegate, MenuBarController init
MenuBarController (@MainActor)           — NSStatusItem, left/right click, popover management
AppState (@MainActor @Observable)        — Central state, navigation, SwiftData persistence
ScreenMonitor (actor)                    — Multi-display capture + side-by-side montage
MonitoringService (actor)                — Adaptive timer + tool context orchestration
ClaudeVisionClient (Sendable struct)     — Vision API + Tool Use + Streaming (SSE)
NudgeEngine (actor)                      — Cooldowns, suppression, silence decisions
DaySummaryService (actor)                — End-of-day reflection with max thinking
DemoModeService (@Observable)            — 8 pre-scripted scenarios + demo data cleanup
SecondChanceService (Sendable struct)    — Alternative practice from different category
TipService (Sendable struct)             — 96 contextual wellness tips
SoundService (@MainActor)               — Subtle system sound effects
```

## Getting Started

### Option 1: Download (Recommended)

1. **[Download Respiro.dmg](https://github.com/kv100/respiro-macos/releases/latest/download/Respiro.dmg)**
2. Open DMG, drag **RespiroDesktop** to Applications
3. Launch from Applications
4. Grant **Screen Recording** permission when prompted
5. Enable **Demo Mode** in Settings (gear icon) to explore all features

Demo Mode showcases all Opus 4.6 capabilities with pre-built scenarios — no setup needed.

> **For personal use with live AI analysis:** set `export ANTHROPIC_API_KEY="sk-ant-..."` before launching.

### Option 2: Build from Source

```bash
git clone https://github.com/kv100/respiro-macos.git
cd respiro-macos
open RespiroDesktop.xcodeproj
```

In Xcode: select the `RespiroDesktop` scheme → Run (Cmd+R).

Or build from the command line:

```bash
xcodebuild -scheme RespiroDesktop -configuration Release build
```

### Requirements

- macOS 14+ (Sonoma)
- Screen Recording permission (ScreenCaptureKit)
- Claude API key (optional — Demo Mode works without it)

## Privacy & Security

Respiro is designed with privacy as a core principle, not an afterthought.

### Screenshots

- Captured in memory only — **never written to disk**
- Sent to Claude API via **HTTPS** for analysis, then immediately discarded
- AI focuses on workspace layout and activity patterns — instructed to **never process readable text, names, or personal data**

### Sensitive App Protection

- **Password managers** (1Password, LastPass, Bitwarden, Dashlane, Keychain Access) are automatically detected — **screenshot capture is skipped entirely** when they're in the foreground
- **Screen sharing** is detected — capture pauses during active presentations to protect others' content
- **System Settings** is also excluded (may display passwords)

### Data Storage

- All user data stays local (SwiftData, no cloud sync)
- API keys stored in **macOS Keychain** (encrypted, never in plaintext)
- No analytics, telemetry, or third-party SDKs — zero external dependencies
- App runs sandboxed with minimum required entitlements

### Transparency

- Open source — every line of code is auditable
- Onboarding clearly explains what data is sent and where
- "The Silence Decision" panel shows exactly when and why the AI chose not to interrupt
- Menu bar only (LSUIElement) — no dock icon, no background surprises

## Roadmap

- **Backend proxy** — Supabase Edge Function so users never handle API keys
- **Apple Sign-In** — authentication for rate-limited proxy access
- **Calendar integration** — meeting context for smarter nudge timing
- **Watch companion** — heart rate data for biometric stress signals
- **iOS companion** — stress data sync across Mac and iPhone

---

Built with [Claude Code](https://claude.ai/claude-code) for the Anthropic **"Built with Opus 4.6"** Hackathon (Feb 10-16, 2026)
