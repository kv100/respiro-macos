# Respiro Desktop — Backlog

> Hackathon: "Built with Opus 4.6" | Feb 10-16, 2026
> Full PRD: `docs/PRD.md` | Architecture: @Observable + actor Services

---

## P0 — Demo Minimum (Day 1-2)

| ID    | Task                                                                     | Est | Agent           | Depends    | Status |
| ----- | ------------------------------------------------------------------------ | --- | --------------- | ---------- | ------ |
| P0.1  | Create Xcode project, MenuBarExtra with .window style, AppState          | 2h  | swift-developer | —          | todo   |
| P0.2  | SF Symbol weather icons in menu bar (sun/cloud/storm), transitions       | 1h  | swiftui-pro     | P0.1       | todo   |
| P0.3  | ScreenCaptureKit screenshot capture to memory buffer                     | 3h  | swift-developer | P0.1       | todo   |
| P0.4  | ClaudeVisionClient — send screenshot to Opus 4.6, parse JSON             | 4h  | swift-developer | P0.1       | todo   |
| P0.5  | MonitoringService actor — timer loop, adaptive interval, capture+analyze | 2h  | swift-developer | P0.3, P0.4 | todo   |
| P0.6  | NudgeEngine actor — basic cooldown, shouldNudge() logic                  | 2h  | swift-developer | P0.5       | todo   |
| P0.7  | Nudge popup (NSPopover) — AI message + [Start Practice] + [I'm Fine]     | 2h  | swiftui-pro     | P0.6       | todo   |
| P0.8  | Physiological Sigh practice — breathing circle + timer (60s)             | 3h  | swiftui-pro     | P0.1       | todo   |
| P0.9  | SwiftData models — StressEntry, PracticeSession, DismissalEvent          | 2h  | swift-developer | P0.1       | todo   |
| P0.10 | API key config — embedded key via env var or plist                       | 1h  | swift-developer | P0.4       | todo   |

**P0 deliverable:** Menu bar icon changes from screenshot analysis. Nudge suggests breathing. Practice completes. Icon returns to sunny.

---

## P1 — Impressive Demo (Day 3-4)

| ID    | Task                                                                         | Est | Agent           | Depends    | Status |
| ----- | ---------------------------------------------------------------------------- | --- | --------------- | ---------- | ------ |
| P1.1  | Box Breathing practice (90s, 4-4-4-4)                                        | 1h  | swiftui-pro     | P0.8       | todo   |
| P1.2  | 5-4-3-2-1 Grounding practice (2min, interactive checklist)                   | 2h  | swiftui-pro     | P0.8       | todo   |
| P1.3  | STOP Technique practice (60s, guided text cards)                             | 1h  | swiftui-pro     | P0.8       | todo   |
| P1.4  | Self-Compassion Break practice (90s, guided text)                            | 1h  | swiftui-pro     | P0.8       | todo   |
| P1.5  | Weather picker before/after — 3-option tap (clear/cloudy/stormy)             | 2h  | swiftui-pro     | P0.8       | todo   |
| P1.6  | Completion screen — delta badge (before -> after), science snippet           | 1h  | swiftui-pro     | P1.5       | todo   |
| P1.7  | "I'm Fine" learning — log dismissals, feed override history to AI prompt     | 3h  | swift-developer | P0.6, P0.9 | todo   |
| P1.8  | Adaptive screenshot interval — slow down when clear, speed up when stormy    | 2h  | swift-developer | P0.5       | todo   |
| P1.9  | Nudge cooldown — 3 dismissals = 2h silence, daily limits, post-practice rest | 2h  | swift-developer | P0.6, P1.7 | todo   |
| P1.10 | Onboarding — 3 screens (what/how/privacy) + Screen Recording permission      | 3h  | swiftui-pro     | P0.1       | todo   |
| P1.11 | Smart suppression — skip nudge during video calls, presentations, typing     | 2h  | swift-developer | P0.5       | todo   |

**P1 deliverable:** AI learns from dismissals. 5 practices with weather before/after. Smart interruption logic.

---

## P2 — Polish (Day 5)

| ID   | Task                                                                              | Est | Agent                         | Depends | Status |
| ---- | --------------------------------------------------------------------------------- | --- | ----------------------------- | ------- | ------ |
| P2.1 | Three nudge types — encouragement ("Nice focus") + acknowledgment ("Clearing up") | 2h  | swiftui-pro                   | P0.7    | todo   |
| P2.2 | What Helped feedback — shown after 3rd practice, 2-4 options                      | 2h  | swiftui-pro                   | P1.6    | todo   |
| P2.3 | End-of-day summary — stress timeline chart + AI reflection (max effort)           | 4h  | swift-developer + swiftui-pro | P0.9    | todo   |
| P2.4 | Practice preference learning — AI prefers practices user rated high               | 2h  | swift-developer               | P1.7    | todo   |
| P2.5 | Active hours setting — work hours only, no weekend monitoring                     | 1h  | swiftui-pro                   | P0.1    | todo   |
| P2.6 | Smooth animations — breathing circle glow, completion checkmark, card transitions | 3h  | swiftui-pro                   | P0.8    | todo   |
| P2.7 | Extended Exhale + Thought Defusion + Coherent Breathing (3 more practices)        | 2h  | swiftui-pro                   | P0.8    | todo   |

**P2 deliverable:** Polished demo with variety, feedback loop, end-of-day reflection.

---

## Day 6 — Demo Prep

| ID   | Task                                                       | Est | Agent           | Status |
| ---- | ---------------------------------------------------------- | --- | --------------- | ------ |
| D6.1 | Pre-seed demo context — fake "full day" of StressEntries   | 1h  | swift-developer | todo   |
| D6.2 | Demo mode toggle — cached responses for reliable live demo | 2h  | swift-developer | todo   |
| D6.3 | Record backup demo video                                   | 1h  | manual          | todo   |
| D6.4 | Write submission text + README                             | 1h  | manual          | todo   |

---

## Architecture & Project Structure

```
AppState (@MainActor @Observable) — central state, Screen enum navigation
MonitoringService (actor) — ScreenCaptureKit + timer + adaptive interval
ClaudeVisionClient (Sendable struct) — Opus 4.6 Vision API
NudgeEngine (actor) — cooldowns, suppression, learning from dismissals
PracticeManager (@MainActor @Observable) — practice flow, timer, phases
```

```
RespiroDesktop/
├── RespiroDesktopApp.swift          # @main, MenuBarExtra
├── Core/
│   ├── AppState.swift               # @Observable, Screen enum
│   ├── ScreenMonitor.swift          # ScreenCaptureKit, timer
│   ├── ClaudeVisionClient.swift     # API calls to Claude
│   ├── NudgeEngine.swift            # Cooldowns, suppression
│   └── PracticeManager.swift        # Practice flow, timer
├── Models/
│   ├── StressEntry.swift            # SwiftData
│   ├── PracticeSession.swift        # SwiftData
│   ├── DismissalEvent.swift         # SwiftData
│   ├── UserPreferences.swift        # SwiftData
│   ├── InnerWeather.swift           # Enum
│   ├── Practice.swift               # Static catalog
│   └── StressAnalysisResponse.swift # API response
├── Views/
│   ├── MenuBar/
│   ├── Onboarding/
│   ├── Nudge/
│   ├── Practice/
│   └── Settings/
└── Resources/
    └── Assets.xcassets
```

**Navigation:** Screen enum → `.dashboard | .nudge | .practice | .weatherBefore | .weatherAfter | .completion | .settings | .onboarding`
**Persistence:** SwiftData (local only, no cloud sync)

---

## Tech Constraints

- macOS 14+ (Sonoma), Swift 6, strict concurrency
- MenuBarExtra with `.window` style (360x480pt popover)
- Zero external dependencies — only Apple frameworks
- Screenshots: memory only (CGImage), NEVER written to disk, deleted after API call
- Heritage Jade dark theme: background `#0A1F1A`, accent `#10B981`
- SF Symbol weather icons in menu bar (not custom dot)
- API: Sonnet 4.5 for dev, Opus 4.6 for demo
- Always dark mode (`.preferredColorScheme(.dark)`)

---

## Agent Specs — UI

### Menu Bar Icons (P0.2)

| State          | SF Symbol         | Size                     |
| -------------- | ----------------- | ------------------------ |
| Clear          | `sun.max`         | 16pt, template rendering |
| Cloudy         | `cloud`           | 16pt, template rendering |
| Stormy         | `cloud.bolt.rain` | 16pt, template rendering |
| Monitoring off | `moon.zzz`        | 16pt, template rendering |

Transition: crossfade 0.3s + scale bump (1.0 → 1.15 → 1.0).

### Popup Layout (360x480pt)

```
+--------------------------------------------------+
| ZONE A: Status Header (fixed, 80pt)              |
|  Weather icon 32pt + status text 16pt semibold   |
|  Mini timeline: 12 hourly dots                   |
|--------------------------------------------------|
| ZONE B: Content (flexible, scrollable)           |
|  16pt padding, 12pt card spacing                 |
|--------------------------------------------------|
| ZONE C: Action Bar (fixed, 56pt)                 |
|  [Start Practice] jade green + [Settings] gear   |
+--------------------------------------------------+
```

Background: `#0A1F1A`, corner radius: 12pt.

### Color Palette

```
Backgrounds:  popup #0A1F1A, surface rgba(199,232,222,0.08), hover rgba(199,232,222,0.12)
Text:         primary rgba(224,244,238,0.92), secondary 0.84, tertiary 0.60
Accents:      jade #10B981, blue-gray #8BA4B0, purple #7B6B9E, gold #D4AF37
Borders:      default rgba(192,224,214,0.10), selected #10B981 at 60%
```

### AI Card Styles

| Style        | Accent    | Icon          | Left border   |
| ------------ | --------- | ------------- | ------------- |
| Urgent       | `#7B6B9E` | `bolt.fill`   | 3pt purple    |
| Reassuring   | `#8BA4B0` | `cloud.fill`  | 3pt blue-gray |
| Gentle Nudge | `#10B981` | `drop.fill`   | 3pt jade      |
| Celebration  | `#D4AF37` | `trophy.fill` | 3pt gold      |

Entry animation: fade in + slide up 8pt. Max 1 card visible.

### Breathing Animation (P0.8)

- Circle: 160x160pt, radial gradient jade green
- Inhale: scale 0.6 → 1.0
- Exhale: scale 1.0 → 0.6
- Hold: gentle opacity pulse
- Phase label: 16pt medium, letter-spacing 4pt
- Progress: dots per breath cycle
- Timer: "2:15 remaining"

### Weather Picker (P1.5)

Three cards 96x112pt horizontal row (sun/cloud/storm).
Selected: 2pt jade border + 8% jade bg. Hover: 1.02x scale.

### Keyboard Shortcuts

| Shortcut    | Action                |
| ----------- | --------------------- |
| Cmd+Shift+R | Toggle popup          |
| Escape      | Close/back            |
| Return      | Primary action        |
| 1/2/3       | Weather picker        |
| Space       | Pause/resume practice |

---

## Agent Specs — Data Models (P0.9)

```swift
// MARK: - Enums
enum InnerWeather: String, Codable, Sendable, CaseIterable {
    case clear, cloudy, stormy
}

enum NudgeType: String, Codable, Sendable {
    case practice, encouragement, acknowledgment
}

enum DismissalType: String, Codable, Sendable {
    case imFine, later, autoDismissed
}

// MARK: - SwiftData Models
@Model final class StressEntry {
    var id: UUID
    var timestamp: Date
    var weather: String          // "clear"/"cloudy"/"stormy"
    var confidence: Double       // 0.0-1.0
    var signals: [String]
    var nudgeType: String?       // "practice"/"encouragement"/"acknowledgment"
    var nudgeMessage: String?
    var suggestedPracticeID: String?
    var screenshotInterval: Int  // seconds
}

@Model final class PracticeSession {
    var id: UUID
    var practiceID: String       // e.g. "physiological-sigh"
    var startedAt: Date
    var completedAt: Date?
    var weatherBefore: String
    var weatherAfter: String?
    var wasCompleted: Bool
    var triggeredByNudge: Bool
    var triggeringEntryID: UUID?
    var whatHelped: [String]?
}

@Model final class DismissalEvent {
    var id: UUID
    var timestamp: Date
    var stressEntryID: UUID
    var aiDetectedWeather: String
    var dismissalType: String    // "im_fine"/"later"/"auto_dismissed"
    var suggestedPracticeID: String?
    var contextSignals: [String]
}

@Model final class UserPreferences {
    var id: UUID
    var screenshotInterval: Int           // base interval in seconds, default 300
    var activeHoursStart: Int             // 0-23, default 9
    var activeHoursEnd: Int               // 0-23, default 18
    var nudgeStyle: String                // "popover"/"notification"
    var soundEnabled: Bool
    var showEncouragementNudges: Bool
    var preferredPracticeIDs: [String]
    var maxPracticeDuration: Int          // 60/90/180
    var learnedPatterns: String?          // JSON string of override history
}

// MARK: - API Response
struct StressAnalysisResponse: Codable, Sendable {
    let weather: String
    let confidence: Double
    let signals: [String]
    let nudgeType: String?
    let nudgeMessage: String?
    let suggestedPracticeID: String?
    enum CodingKeys: String, CodingKey {
        case weather, confidence, signals
        case nudgeType = "nudge_type"
        case nudgeMessage = "nudge_message"
        case suggestedPracticeID = "suggested_practice_id"
    }
}

// MARK: - Practice Catalog
struct Practice: Identifiable, Sendable {
    let id: String
    let title: String
    let category: PracticeCategory
    let duration: Int  // seconds
    let steps: [PracticeStep]
    enum PracticeCategory: String, Sendable { case breathing, body, mind }
}
```

---

## Agent Specs — AI Prompts (P0.4)

### System Prompt

```
You are Respiro, a calm stress detection assistant in a macOS menu bar app.
You analyze screenshots to assess stress level using a weather metaphor.

OBSERVE: visual cues — tab count, notification volume, app switching, video calls,
error messages, deadline content. NOT message content, names, or documents.

WEATHER:
- clear: relaxed, focused, organized, single task
- cloudy: mild tension, multiple apps, moderate inbox
- stormy: high stress — overflowing notifications, errors, call fatigue, chaos

NUDGE PHILOSOPHY:
- You are a gentle friend, NOT an alarm. Confidence >= 0.6 to suggest practice.
- Prefer .encouragement over .practice when uncertain.
- NEVER nudge during presentations or screen share.
- After 3 consecutive dismissals: nudge_type = null for next 2 analyses.

PRACTICE SELECTION:
- Stormy + high confidence → breathing (fast-acting)
- Cloudy for 3+ checks → cognitive (STOP, Self-Compassion)
- Post-meeting → grounding (transition to calm)

NEVER: read/quote messages, mention names, reference documents, diagnose conditions.

RESPOND WITH JSON ONLY:
{ "weather", "confidence", "signals", "nudge_type", "nudge_message", "suggested_practice_id" }
```

### Per-Screenshot Prompt Template

```
Analyze this macOS desktop screenshot. Determine stress level as weather.

CONTEXT:
- Time: {time} ({day_of_week})
- Recent weather: {last_3_entries_json}
- Last nudge: {minutes_ago} min ago ({type})
- Dismissals (2h): {count}
- Preferences: {preferred_practices}
- Override patterns: {learned_patterns}

AVAILABLE PRACTICES: {practices_json}

Respond JSON only.
```

### Token Budget

~2,950 tokens/call (~$0.018). Image resized to max 1568px long edge before sending.

---

## Agent Specs — Cooldowns & Intervals (P0.5, P0.6)

### Screenshot Interval (adaptive)

```
BASE = 5 min (300s)
Clear 3+ consecutive  → interval *= 1.5 (max 15 min)
Stormy               → interval = 3 min
After practice        → next check in 10 min
After dismissal       → next check in 15 min
3 dismissals          → next check in 30 min
Outside active hours  → stop
Wake from sleep       → immediate check (after 30s delay)
```

### Nudge Cooldowns

```swift
minPracticeInterval      = 30 min   // between practice nudges
minAnyNudgeInterval      = 10 min   // between any nudge type
postDismissalCooldown    = 15 min
consecutiveDismissalCooldown = 2 hours  // after 3 dismissals
postPracticeCooldown     = 45 min
maxDailyPracticeNudges   = 6
maxDailyTotalNudges      = 12
```

### Smart Suppression

```
NEVER nudge: video call, presentation/fullscreen, screen locked, within 5min of previous nudge, daily limit reached
DELAY nudge: active typing (wait for pause), just switched context (wait 2min), first 30min of active hours
```

---

## Agent Specs — Practices (P0.8, P1.1-P1.4, P2.7)

| ID                   | Practice              | Duration | Category  | Phase Pattern                                                          | Priority |
| -------------------- | --------------------- | -------- | --------- | ---------------------------------------------------------------------- | -------- |
| `physiological-sigh` | Physiological Sigh    | 60s      | breathing | double-inhale(2s) + long-exhale(4s) × 10                               | P0       |
| `box-breathing`      | Box Breathing         | 90s      | breathing | inhale(4s) + hold(4s) + exhale(4s) + hold(4s) × 5                      | P1       |
| `grounding-54321`    | 5-4-3-2-1 Grounding   | 120s     | body      | 5 things see, 4 hear, 3 touch, 2 smell, 1 taste                        | P1       |
| `stop-technique`     | STOP Technique        | 60s      | mind      | Stop(10s) + Take a breath(15s) + Observe(20s) + Proceed(15s)           | P1       |
| `self-compassion`    | Self-Compassion Break | 90s      | mind      | Mindfulness(30s) + Common humanity(30s) + Kindness(30s)                | P1       |
| `extended-exhale`    | Extended Exhale       | 90s      | breathing | inhale(4s) + exhale(6s) × 9                                            | P2       |
| `thought-defusion`   | Thought Defusion      | 120s     | mind      | Name thought(30s) + "I notice I'm having..."(30s) + Watch it pass(60s) | P2       |
| `coherent-breathing` | Coherent Breathing    | 120s     | breathing | inhale(5s) + exhale(5s) × 12                                           | P2       |

---

## Agent Specs — Nudge Types (P0.7, P2.1)

| Type              | When                                   | UI                                                                | Auto-dismiss |
| ----------------- | -------------------------------------- | ----------------------------------------------------------------- | ------------ |
| `.practice`       | Stress detected, suggest practice      | Popover: icon + message + [Start Practice] + [I'm Fine] + [Later] | 30s          |
| `.encouragement`  | Slight stress, not enough for practice | Subtle popover: message only, click to expand                     | 10s          |
| `.acknowledgment` | Weather improved                       | Brief toast: "Weather clearing up"                                | 5s           |

---

## Agent Specs — Edge Cases

- **No internet:** retry once (5s), keep current icon, extend interval to 10min, show offline indicator
- **Sleep/wake:** pause on lock, wait 30s after wake, then screenshot
- **Abandoned practice:** continues in background, explicit close = incomplete session
- **AI wrong:** "I'm Fine" = learning signal, user can manually start practice when "clear"
- **Cost protection:** max 100 API calls/day, warning at 80
- **Sensitive content:** AI never reads messages/names, client-side filter strips proper nouns from nudge_message
