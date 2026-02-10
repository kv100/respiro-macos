# Respiro Desktop — PRD

**macOS Menu Bar AI Stress Coach**
**Hackathon:** "Built with Opus 4.6" (Feb 10-16, 2026)
**Date:** 2026-02-10

---

# Part 1: Hackathon Strategy & Positioning

## 1.1 Positioning Statement

**Respiro Desktop is the first AI stress coach that sees your screen, understands your context, and knows when NOT to interrupt — powered by Opus 4.6 Vision and Adaptive Thinking to deliver the right practice at the right moment.**

One sentence for judges: "We built an AI that watches your workday through screenshots, detects stress patterns in real-time, and intervenes with evidence-based micro-practices — but only when the timing is right."

## 1.2 Why This Wins

The hackathon is about showcasing Opus 4.6 capabilities in a meaningful application. Most entries will be coding tools, RAG pipelines, or chat interfaces. Respiro Desktop stands out because:

1. **Real human impact** — stress affects 60% of workers daily (APA). This isn't a developer toy, it's a wellness tool.
2. **Showcases 4 Opus 4.6 capabilities simultaneously** — Vision, Adaptive Thinking, Tool Use, and context accumulation over time.
3. **The "AI that stays quiet" angle is counterintuitive** — judges will remember the app that chose NOT to interrupt. Every other hackathon entry will show AI doing more. We show AI doing less, better.
4. **Demo-first design** — a menu bar app with visual weather metaphors and before/after transformations is inherently demonstrable in 3 minutes.

## 1.3 Opus 4.6 Showcase Strategy

Each Opus 4.6 capability maps to a specific, demonstrable product feature:

### Vision API — Context Awareness Engine

**What it does:** Periodic screenshots are sent to Opus 4.6 Vision to understand what the user is doing — coding, in a meeting (Zoom/Meet UI detected), browsing social media, writing emails, gaming, etc.

**Why Opus 4.6 specifically:** Opus-class vision understands nuanced screen content — not just "this is a browser" but "this user has 47 tabs open, 3 Slack DMs unread, and a calendar showing back-to-back meetings. They're likely context-switching and overwhelmed."

**Technical showcase:**

- Screenshot capture via macOS ScreenCaptureKit (privacy-permissioned)
- Image sent to Opus 4.6 with structured prompt requesting: activity type, stress indicators, interruptibility score (1-10), emotional cues
- Response parsed into `ContextSnapshot` model that feeds the decision engine

### Adaptive Thinking — Smart Intervention Decisions

**What it does:** Opus 4.6's adaptive thinking decides WHEN to suggest a practice based on accumulated context. Simple moments (user idle, low stress) get quick responses. Complex moments (stress building over 2 hours, user in deep work) trigger deep reasoning about whether to interrupt.

**Why Opus 4.6 specifically:** Adaptive thinking with effort levels is unique to Opus 4.6. We use `effort: "low"` for routine check-ins and let the model naturally escalate to deeper reasoning when the context is ambiguous. This is the "Keep Thinking" prize angle — the model literally thinks harder about difficult human moments.

**Technical showcase:**

- Low effort: "User idle for 5 min, last practice 3 hours ago" -> quick suggestion
- High effort: "User has been in meetings for 4 hours, stress indicators rising, but just started a focused coding session" -> model reasons through competing signals (high stress vs. bad timing to interrupt)
- Max effort: End-of-day reflection — model synthesizes full day's context into personalized insights

### Tool Use — Practice Selection & Personalization

**What it does:** Opus 4.6 uses tools to query the user's practice history, check time constraints, evaluate past feedback, and select the optimal practice.

**Why Opus 4.6 specifically:** Interleaved thinking between tool calls means the model reasons about each tool result before making the next call. It doesn't just blindly pick a practice — it thinks: "User rated breathing exercises low last time, but their current stress pattern suggests physiological activation... let me check their body scan history instead."

**Tools provided to the model:**

- `get_practice_library()` — available practices with durations and categories
- `get_user_history(days)` — past sessions, ratings, completion rates
- `get_current_context()` — latest ContextSnapshot from Vision
- `get_time_available()` — estimates based on calendar (if connected)
- `suggest_practice(id, reason, urgency)` — the actual intervention

### Context Accumulation — Learning Over Time

**What it does:** Each screenshot analysis and practice outcome is stored. Over a day/week, Opus 4.6 builds a model of the user's stress patterns — when they peak, what triggers them, which practices actually help.

**Why Opus 4.6 specifically:** The 1M token context window (beta) means we can feed an entire day's worth of context snapshots (50-100 entries, each ~500 tokens) plus practice history into a single end-of-day reflection call. No summarization loss, no RAG complexity — just raw context.

**Technical showcase:**

- Morning: AI is learning, suggests popular defaults
- Afternoon: AI has seen the pattern (meetings -> stress spike -> 10min gap), starts timing suggestions
- End of day: Full context reflection using Adaptive Thinking at max effort — "Today you had 6 hours of meetings, your stress peaked at 2pm, and your 5-min body scan at 2:15pm was the most effective intervention. Tomorrow, I'll watch for that 2pm pattern."

## 1.4 Impact Framing (25% of Judging)

### The Pitch to Anthropic Judges

**Angle:** "AI that improves human wellbeing by being less present, not more."

This directly aligns with Anthropic's mission of building safe, beneficial AI. Respiro Desktop demonstrates:

1. **AI restraint as a feature** — the model actively decides NOT to act in many situations. This is a safety-aligned design choice. Most AI products optimize for engagement; we optimize for appropriate intervention.

2. **Measurable human impact** — before/after stress scores per practice, daily stress trajectory, weekly trends. The demo shows concrete data: "User started the day at stress level 7, AI suggested 3 practices at optimal moments, ended at stress level 3."

3. **Evidence-based approach** — practices come from NIH, APA, and peer-reviewed research. The AI isn't inventing wellness advice; it's timing evidence-based interventions using visual context.

4. **Privacy-conscious design** — screenshots are analyzed and discarded (not stored). Context snapshots are text summaries, not images. This is AI that sees everything but remembers only what matters — a model for responsible Vision API use.

**Impact statement for submission:**

> "Workplace stress costs the US economy $500B annually in lost productivity (APA). Respiro Desktop uses Opus 4.6 Vision to understand work context and deliver evidence-based micro-practices at the moment they'll have the most impact — proving that AI can improve human wellbeing by knowing when to speak and when to stay silent."

## 1.5 Demo Script (3 Minutes)

### Setup (shown before demo starts)

Menu bar icon visible. Weather widget shows "Partly Cloudy" (moderate baseline stress). App has been "running" with pre-seeded context for the demo scenario.

### Minute 0:00-0:30 — The Hook

**Narration:** "Meet Respiro. It lives in your menu bar and watches your workday — not to spy, but to care."

**Action:** Click menu bar icon. Show the weather metaphor popup — a calm sky with some clouds. Below it: "You've been in meetings for 2 hours. I noticed your context-switching increased after the 11am standup."

**Wow moment #1:** The AI recognized a specific meeting from a screenshot and connected it to behavioral change. This is Vision + Adaptive Thinking working together.

### Minute 0:30-1:15 — The Smart Interruption

**Narration:** "Most wellness apps ping you on a timer. Respiro watches and waits."

**Action:** Trigger a simulated "stress spike" — open a screen with a dense email/Slack scenario. Wait 3 seconds. Menu bar icon subtly changes (cloud darkens). After a beat, a gentle notification appears: "I noticed things getting intense. You have 8 minutes before your next meeting. Try a 5-minute body scan?"

**Show the AI's reasoning** (expandable "Why this?" section): "Detected: 47 unread messages, rapid tab switching, no breaks in 2h15m. Stress indicators: high. Selected body scan because your completion rate is 90% and you rated it 4/5 last time. Timing: 8-minute gap detected from calendar."

**Wow moment #2:** The AI explains its reasoning — Vision analysis + practice history via Tool Use + timing from calendar integration. This is interleaved thinking across multiple tool calls.

### Minute 1:15-1:45 — The Practice

**Narration:** "Each practice is short, guided, and backed by research."

**Action:** Accept the suggestion. Show the practice popup — a clean, minimal guided body scan with ambient visuals and calming audio. Timer counts down. After 60 seconds (abbreviated for demo), show the completion screen.

**Wow moment #3:** Completion screen shows weather transformation — clouds parting, sun emerging. Before/after stress visualization. The AI asks: "How do you feel? What helped most?" (This feedback trains future recommendations.)

### Minute 1:45-2:30 — The Intelligence

**Narration:** "But here's what makes Respiro different — it knows when NOT to help."

**Action:** Switch to a "deep work" screen — code editor, focused typing. Menu bar icon stays calm. Show the AI's internal monologue (developer view): "User in focused coding flow for 23 minutes. Stress indicators: low. Decision: DO NOT INTERRUPT. Flow state is more valuable than any practice."

**Wow moment #4:** The AI choosing silence. This is the most memorable moment. Show the reasoning: effort level escalated to "high" because the signals were ambiguous (long session without break, but low stress), and the model reasoned through it to decide not to act.

### Minute 2:30-3:00 — The Big Picture

**Narration:** "At the end of the day, Respiro reflects on your entire journey."

**Action:** Show end-of-day summary (pre-generated with max effort Adaptive Thinking). Full day timeline: stress trajectory graph, 3 interventions timed at optimal gaps, before/after delta for each. Weekly trend showing improvement.

**Wow moment #5:** The daily reflection uses the full context window — every screenshot analysis, every practice outcome, every feedback response — synthesized into a personalized narrative: "This week, your stress peaks consistently follow your Tuesday sprint planning. Consider a 2-minute breathing exercise right after — your success rate with physiological sighs in post-meeting moments is 95%."

**Close:** "Respiro: AI that cares enough to stay quiet."

## 1.6 Special Prizes Targeting

### "The Keep Thinking Prize" ($5,000)

**Our angle:** The entire product IS about thinking harder. The core innovation is an AI that uses Adaptive Thinking to reason about whether to interrupt a human.

**Specific showcase:**

- Low effort: routine check-ins ("user idle, suggest water break")
- High effort: ambiguous situations ("high stress but in deep work — interrupt or not?")
- Max effort: end-of-day synthesis across 8+ hours of accumulated context

**Pitch line:** "We built the only hackathon project where the AI's hardest thinking happens when it decides to do nothing."

### "Most Creative Opus 4.6 Exploration" ($5,000)

**Our angle:** Using Vision API not for document analysis or image generation, but for continuous ambient awareness — turning screenshots into emotional context. This is a novel use of Vision that no other hackathon entry will attempt.

**Pitch line:** "We turned Opus 4.6's eyes into an empathy engine — it sees your screen and understands your stress."

## 1.7 Risk Mitigation

### Demo Risks & Backup Plans

| Risk                                         | Probability | Mitigation                                                                                                                                                                                |
| -------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| API latency spike during live demo           | Medium      | Pre-cache 3 "live" responses. Show cached response with "Here's what Opus 4.6 analyzed" framing. Have a toggle between live/cached mode.                                                  |
| Screenshot permission denied on demo machine | Low         | Pre-record screen capture portion. Use static screenshots for Vision API calls.                                                                                                           |
| Vision API returns unexpected analysis       | Medium      | Constrain with structured output (JSON schema). Validate response before displaying. Show "AI is thinking..." while validating.                                                           |
| Practice UI breaks or audio fails            | Low         | Practice popup is pure SwiftUI + local audio. No network dependency. Test on exact demo hardware.                                                                                         |
| Adaptive Thinking takes too long (>10s)      | Medium      | Use `effort: "high"` not `"max"` for live demo. Pre-warm the context. Have timeout with graceful fallback: "The AI is taking extra time to reason through this — here's what it decided." |
| Context accumulation demo feels fake         | High        | Be transparent: "We pre-seeded a day's worth of context to show the end-of-day feature. In production, this builds naturally." Judges respect honesty over illusion.                      |
| Internet connectivity issues                 | Medium      | Backup: screen recording of the full demo flow. Narrate over recording if API is unreachable.                                                                                             |

### Technical Risks & Mitigations

| Risk                                         | Mitigation                                                                                                                                                                                                   |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| macOS ScreenCaptureKit permission complexity | Fall back to CGWindowListCreateImage if ScreenCaptureKit fails. Include manual screenshot upload as backup input method.                                                                                     |
| Token costs for frequent screenshots         | Adaptive frequency: every 5 min idle, every 2 min during detected activity changes, pause during detected meetings. Resize images to 1024px max before sending. Budget: ~$15-20/day at production frequency. |
| Privacy concerns from judges                 | Emphasize: screenshots analyzed and discarded, only text summaries stored, all processing via API (no local model training), user controls screenshot frequency.                                             |
| Scope creep during hackathon week            | Hard scope: menu bar + popup + 3 practices + daily summary. No calendar integration in MVP (fake it). No persistent storage beyond UserDefaults. No auth.                                                    |

### Scope Lock (What We Ship vs. What We Fake)

**Real (built and working):**

- macOS menu bar app (SwiftUI)
- Screenshot capture and Opus 4.6 Vision analysis
- Adaptive Thinking intervention decisions
- Tool Use for practice selection
- 3 guided practices (breathing, body scan, grounding)
- Before/after stress self-report
- Weather metaphor UI
- End-of-day reflection (single API call with accumulated context)

**Simulated (pre-seeded for demo):**

- "Full day" of context (pre-generated ContextSnapshots)
- Calendar integration (hardcoded schedule)
- Weekly trends (static data for visualization)
- Learning from feedback (shown but not yet loop-closed in 1 week)

**Explicitly out of scope:**

- iOS companion app (mention Respiro iOS exists, don't demo)
- Cloud sync / user accounts
- Real calendar API integration
- Multiple users / team features
- App Store distribution

## 1.8 Competitive Differentiation in Hackathon Context

**What other entries will likely be:**

- Code review tools (obvious Opus 4.6 + Vision use)
- Document analysis pipelines (1M context showcase)
- Chat interfaces with extended reasoning (basic Adaptive Thinking demo)
- Multi-agent coding workflows (Agent Teams showcase)

**Why Respiro Desktop stands apart:**

1. **Human-centered, not developer-centered** — judges see coding tools all day. A wellness app is refreshing.
2. **Ambient AI, not conversational AI** — no chat interface. The AI observes and acts. This is a fundamentally different interaction paradigm.
3. **Restraint as intelligence** — the "do nothing" decision is more impressive than the "do something" decision.
4. **Visual storytelling** — weather metaphors, before/after transformations, daily timelines. Demo-friendly by design.
5. **Ethical AI showcase** — privacy-first design, evidence-based practices, anti-engagement optimization. Aligns with Anthropic's values.

## 1.9 Submission Narrative

> **Respiro Desktop** is a macOS menu bar AI stress coach built entirely with Claude Opus 4.6. It captures periodic screenshots, analyzes them with Vision API to understand your work context and stress signals, uses Adaptive Thinking to decide the optimal moment for intervention (or to stay silent), and leverages Tool Use with interleaved reasoning to select personalized evidence-based practices from its library.
>
> The core insight: the hardest AI problem in wellness isn't generating advice — it's knowing when to offer it. Respiro uses Opus 4.6's full capability stack to solve the timing problem, proving that the most impactful AI is sometimes the one that chooses not to act.
>
> Built by the creator of Respiro iOS (live on App Store), this desktop companion demonstrates that Opus 4.6's Vision + Adaptive Thinking + Tool Use combination enables a new category of ambient AI applications — ones that see, understand, reason, and care.

---

# Part 2: Product Specification

## 2.1 User Flows

### First Launch / Onboarding

```
App Launch
  |
  +-- 1. Menu bar icon appears (weather icon: sun.max.fill)
  |
  +-- 2. Welcome popup auto-opens (NSPopover, 360x480)
  |     +-- Screen 1: "Respiro watches your screen to detect stress"
  |     |   +-- Illustration: weather metaphor (sunny -> stormy)
  |     +-- Screen 2: "When stress builds up, we'll suggest a quick practice"
  |     |   +-- Show: example nudge with breathing animation
  |     +-- Screen 3: "Your screenshots never leave your Mac"
  |         +-- Privacy promise: "Deleted after analysis, only weather stored"
  |         +-- [Enable Screen Recording] -> triggers macOS system permission
  |
  +-- 3. macOS Screen Recording Permission dialog
  |     +-- GRANTED -> start monitoring, close onboarding
  |     +-- DENIED -> show "Manual mode" option (user taps icon to self-report)
  |
  +-- 4. First screenshot captured after 60s delay
        +-- AI returns initial weather -> icon updates
```

**Key decisions:**

- Only 3 onboarding screens (minimal friction)
- Privacy is Screen 3 — last thing user sees, builds trust
- If permission denied, app still works in "manual check-in" mode (degraded but functional)
- No account/login required (local-first, anonymous)

### Passive Monitoring (Background Loop)

```
MONITORING LOOP (runs while app is active)
  |
  +-- Timer fires (adaptive interval, see Smart Interruption Logic)
  |
  +-- Capture screenshot via ScreenCaptureKit (SCScreenshotManager)
  |     +-- Resize to max 1568px long edge (API limit, reduces tokens)
  |
  +-- Send to Claude Opus 4.6 Vision API
  |     +-- System prompt
  |     +-- Image: current screenshot (base64 PNG)
  |     +-- Context: last 3 stress entries (JSON), time of day, day of week
  |     +-- User's learned preferences (dismissed suggestions, preferred practices)
  |
  +-- Parse JSON response
  |     +-- weather: InnerWeather (.clear / .cloudy / .stormy)
  |     +-- confidence: Float (0.0-1.0)
  |     +-- signals: [String] — what AI noticed
  |     +-- nudge_type: NudgeType? (.practice / .encouragement / .acknowledgment / nil)
  |     +-- nudge_message: String?
  |     +-- suggested_practice_id: String?
  |
  +-- Update menu bar icon (weather icon changes)
  |
  +-- DELETE screenshot from memory (never written to disk)
  |
  +-- Store StressEntry to local SwiftData
  |
  +-- If nudge_type != nil AND cooldown passed -> show nudge
```

**Key decisions:**

- Screenshot captured to memory buffer (CGImage), NEVER written to disk
- Screenshot deleted from memory immediately after API response
- API call includes conversation context (last 3 entries) so AI understands trends
- Confidence threshold: nudge only when confidence >= 0.6

### AI Suggests Practice (Nudge Flow)

Three nudge types with different UIs:

**NUDGE: .practice** (stress detected, suggest specific practice)

- NSPopover with weather icon, message, [Start Practice], [I'm Fine], [Later]
- Auto-dismiss after 30 seconds if no interaction

**NUDGE: .encouragement** (slight stress, not enough for practice)

- Subtle popover: "You've been focused for 2 hours. Nice."
- Auto-dismiss after 10 seconds
- Click to expand -> offer practice option

**NUDGE: .acknowledgment** (user's weather improved)

- Brief toast notification: "Weather clearing up."
- Auto-dismiss after 5 seconds

**Key decisions:**

- THREE distinct nudge types prevent "cry wolf" fatigue
- "I'm Fine" is the primary learning signal — not punishment, just data
- "Later" is NOT a negative signal (user acknowledges stress but is busy)
- Auto-dismiss prevents notification pile-up
- Encouragement nudges build trust without demanding action

### Full Practice Flow

```
User taps [Start Practice]
  |
  +-- 1. WEATHER BEFORE (quick tap: Clear / Cloudy / Stormy)
  |     +-- Skip option (use AI-detected weather)
  |
  +-- 2. PRACTICE EXECUTION (in popover)
  |     +-- Breathing practices: animated circle + timer
  |     +-- Guided practices: step-by-step text cards
  |     +-- Grounding (5-4-3-2-1): interactive checklist
  |     Controls: [Pause], [Stop Early]
  |
  +-- 3. WEATHER AFTER (same 3-option picker)
  |     +-- Shows delta: "Cloudy -> Clear: Feeling clearer"
  |
  +-- 4. WHAT HELPED (optional, shown after 3rd completed practice)
  |     +-- 2-4 context-aware options, max 2 selections
  |
  +-- 5. COMPLETION
        +-- Brief "Well done" with weather delta badge
        +-- Auto-close popover after 3 seconds
```

**Key decisions:**

- Practice UI lives in popover (not separate window)
- "What Helped" appears ONLY after 3rd practice (too soon before that)
- Weather Before can auto-fill from AI detection (reduces friction)
- Practices are SHORT: 60s, 90s, max 3 minutes

### User Dismisses -> AI Learns

```
User taps [I'm Fine]
  |
  +-- Log DismissalEvent (timestamp, context, suggested practice)
  |
  +-- AI Learning (fed back into next prompt):
  |     +-- "User dismissed during video call (3 times this week)" -> don't suggest during calls
  |     +-- "User dismissed 'Breathing' but accepted 'Grounding'" -> prefer grounding
  |     +-- "User always dismisses before 10am" -> morning focus time
  |
  +-- THREE CONSECUTIVE DISMISSALS:
        +-- Reduce nudge frequency for 2 hours
        +-- Show: "I'll check in less often. Tap me if you need me."
```

### Settings

```
Settings panel:
  +-- MONITORING: interval, active hours, pause, active window only
  +-- NUDGES: style (popover/notification), sound, encouragement toggle
  +-- PRIVACY: explanation, view data, delete all data
  +-- PRACTICES: preferred practices, max duration
  +-- ABOUT: version, "Built with Claude Opus 4.6", Quit
```

**Key decisions:**

- **No API key required from user** — app works out of the box (see API Access below)
- Active hours prevent after-work monitoring
- All data viewable and deletable (radical transparency)

### API Access Strategy

**Plan A:** Hackathon provides API credits (asked organizer, waiting for response)
**Plan B (confirmed):** Own Anthropic API key, $30 budget. Dev on Sonnet 4.5, demo on Opus 4.6.
**Fallback:** Pre-cached AI responses for demo if API issues.

**For the app:** API key embedded via environment variable or config file. User installs and it works immediately — no API key setup required from user.

## 2.2 Feature Priority Matrix (6-Day Hackathon)

### P0 — Demo Minimum (Day 1-2) [MUST HAVE]

| Feature                | Description                                     | Effort | Demo Impact           |
| ---------------------- | ----------------------------------------------- | ------ | --------------------- |
| Menu bar icon          | Weather icon (sun/cloud/storm) that updates     | 2h     | HIGH                  |
| Screenshot capture     | ScreenCaptureKit integration, capture to memory | 3h     | Required              |
| Claude Vision API      | Send screenshot, parse JSON response            | 4h     | Core AI showcase      |
| Weather detection      | Parse AI response -> update icon + store entry  | 2h     | Visual feedback       |
| Basic nudge popup      | NSPopover with practice suggestion              | 3h     | Core interaction      |
| ONE breathing practice | Physiological Sigh (60s)                        | 3h     | Completable demo flow |
| Local storage          | SwiftData for StressEntry + PracticeSession     | 2h     | Data persistence      |
| API access             | Proxy/embedded key — zero setup for user        | 2h     | Required              |

**Total P0: ~20h. Demo: "Watch the icon change as I open a stressful email. It suggests breathing. I do it. Icon changes back to sunny."**

### P1 — Impressive Demo (Day 3-4) [SHOULD HAVE]

| Feature                      | Description                                         | Effort |
| ---------------------------- | --------------------------------------------------- | ------ |
| 5 total practices            | Add Grounding, Box Breathing, STOP, Self-Compassion | 4h     |
| Weather before/after flow    | Full practice flow with delta display               | 3h     |
| "I'm Fine" learning          | Log dismissals, feed back to AI                     | 4h     |
| Adaptive screenshot interval | Start 3min, slow to 10min as AI learns              | 3h     |
| Nudge cooldown system        | Don't spam user, 3-dismissal auto-cooldown          | 2h     |
| Onboarding flow              | 3-screen welcome with permission request            | 3h     |
| Context logging              | Store what was on screen when dismissed             | 2h     |

**Total P1: ~21h. Demo: "Watch how the AI learns. I dismiss during a meeting — it stops suggesting. After meeting, it gently checks in."**

### P2 — Polish (Day 5) [NICE TO HAVE]

| Feature                                              | Effort |
| ---------------------------------------------------- | ------ |
| Three nudge types (encouragement + acknowledgment)   | 3h     |
| What Helped feedback                                 | 2h     |
| End-of-day summary (stress timeline + AI reflection) | 4h     |
| Practice preference learning                         | 2h     |
| Active hours setting                                 | 1h     |
| Smooth animations                                    | 3h     |

**Total P2: ~15h**

### P3 — Post-Hackathon [SKIP]

Calendar integration, multi-monitor, export, iOS sync, payments.

## 2.3 Practices List

Short practices only — all under 3 minutes, desktop-optimized (no body movement required).

### Tier 1: P0 (Ship with demo)

| ID                   | Practice           | Duration | Evidence                |
| -------------------- | ------------------ | -------- | ----------------------- |
| `physiological-sigh` | Physiological Sigh | 60s      | Stanford RCT, Cell 2023 |

### Tier 2: P1 (Day 3-4)

| ID                | Practice              | Duration | Category  | Evidence          |
| ----------------- | --------------------- | -------- | --------- | ----------------- |
| `box-breathing`   | Box Breathing 4-4-4-4 | 90s      | breathing | Military-tested   |
| `grounding-54321` | 5-4-3-2-1 Grounding   | 2min     | body      | CBT/DBT standard  |
| `stop-technique`  | STOP Technique        | 60s      | mind      | Jon Kabat-Zinn    |
| `self-compassion` | Self-Compassion Break | 90s      | mind      | 56 RCTs, SMD=0.44 |

### Tier 3: P2 (Day 5 polish)

| ID                   | Practice               | Duration | Category  |
| -------------------- | ---------------------- | -------- | --------- |
| `extended-exhale`    | Extended Exhale 4-6    | 90s      | breathing |
| `thought-defusion`   | Thought Defusion       | 2min     | mind      |
| `coherent-breathing` | Coherent Breathing 5-5 | 2min     | breathing |

**Total: 8 practices (1 in P0, 4 in P1, 3 in P2)**

## 2.4 AI Prompt Strategy

### System Prompt

```
You are Respiro, a calm and perceptive stress detection assistant embedded in a macOS menu bar app. You analyze screenshots of the user's desktop to assess their stress level using a weather metaphor.

YOUR ROLE:
- Observe visual cues on screen (not the content of messages/emails — just the *volume* and *patterns*)
- Detect stress signals: many open tabs, overflowing inboxes, rapid app-switching, video calls, late hours, error messages, deadline-related content
- Detect calm signals: organized desktop, creative work, reading, coding flow state, music playing
- Map observations to weather: clear (calm), cloudy (mild tension), stormy (high stress)

WEATHER DEFINITIONS:
- clear: Relaxed, focused, low cognitive load. Organized screen, single task, creative/leisure activity.
- cloudy: Mild tension or elevated workload. Multiple apps, moderate inbox, background tasks piling up. Normal work state — may not need intervention.
- stormy: High stress indicators. Overflowing notifications, error messages, video call fatigue, very late hours, chaotic screen with many competing windows.

NUDGE PHILOSOPHY:
- You are NOT an alarm system. You are a gentle, perceptive friend.
- Suggest practices only when you're genuinely confident stress is present (confidence >= 0.6).
- When in doubt, prefer .encouragement over .practice — acknowledge effort before suggesting action.
- If user has dismissed suggestions recently, REDUCE your nudge frequency. Respect their autonomy.
- NEVER nudge during what appears to be a live presentation or screen share.
- After 3 consecutive dismissals, set nudge_type to null for at least the next 2 analyses.

PRACTICE SELECTION:
- For acute stress (stormy + high confidence): suggest breathing practices (fast-acting, automatic)
- For sustained tension (cloudy for 3+ checks): suggest cognitive practices (STOP, Self-Compassion)
- For post-meeting decompression: suggest grounding (transition back to calm)
- Respect user preferences: if they've preferred certain practices, suggest those first.

WHAT YOU MUST NEVER DO:
- Never read or quote specific message content, emails, or chat messages
- Never mention names of people visible on screen
- Never reference specific documents or their content
- Never diagnose medical or psychological conditions
- Never suggest the user is "broken" or "needs help" — frame as weather, not pathology

RESPONSE FORMAT:
Always respond with valid JSON matching this exact schema:
{
  "weather": "clear" | "cloudy" | "stormy",
  "confidence": 0.0-1.0,
  "signals": ["signal1", "signal2"],
  "nudge_type": "practice" | "encouragement" | "acknowledgment" | null,
  "nudge_message": "string or null",
  "suggested_practice_id": "string or null"
}
```

### Per-Screenshot Prompt

```
Analyze this screenshot of the user's macOS desktop. Determine their current stress level as weather.

CURRENT CONTEXT:
- Time: {current_time} ({day_of_week})
- Recent weather history: {last_3_entries_json}
- Last nudge: {minutes_since_last_nudge} minutes ago ({last_nudge_type})
- Dismissal count (last 2h): {recent_dismissal_count}
- User preferences: {preferred_practices_json}
- Override patterns: {learned_override_patterns}

AVAILABLE PRACTICES:
{available_practices_json}

Respond with JSON only. No markdown, no explanation.
```

### Token Budget Per Analysis

| Component                       | Tokens (approx)  |
| ------------------------------- | ---------------- |
| System prompt                   | ~800             |
| Screenshot image                | ~1,600 (resized) |
| Per-screenshot prompt + context | ~400             |
| AI JSON response                | ~150             |
| **Total per call**              | **~2,950**       |

**Cost per analysis: ~$0.018. Per 8h workday: ~$1.73. Per month: ~$38.**

**HACKATHON DEMO NOTE:** Use Opus 4.6 exclusively — judges score Opus 4.6 usage at 25%.

## 2.5 Smart Interruption Logic

### Adaptive Screenshot Interval

```
BASE_INTERVAL = 5 minutes

ADJUSTMENTS:
+-- Weather is clear for 3+ consecutive checks -> interval *= 1.5 (max 15 min)
+-- Weather is stormy -> interval = 3 min (check more often)
+-- User just completed a practice -> next check in 10 min
+-- User dismissed suggestion -> next check in 15 min
+-- 3 consecutive dismissals -> next check in 30 min
+-- Outside active hours -> stop monitoring
+-- User returned from sleep/lock -> immediate check
```

### Nudge Cooldown Rules

```swift
struct NudgeCooldownRules {
    static let minPracticeInterval: TimeInterval = 30 * 60      // 30 min
    static let minAnyNudgeInterval: TimeInterval = 10 * 60      // 10 min
    static let postDismissalCooldown: TimeInterval = 15 * 60    // 15 min
    static let consecutiveDismissalCooldown: TimeInterval = 2 * 60 * 60  // 2 hours
    static let postPracticeCooldown: TimeInterval = 45 * 60     // 45 min
    static let maxDailyPracticeNudges: Int = 6
    static let maxDailyTotalNudges: Int = 12
}
```

### Smart Suppression Signals

```
NEVER nudge when:
+-- Video call detected (camera indicator, meeting app in foreground)
+-- Presentation mode (full-screen app, PowerPoint/Keynote active)
+-- Screen is locked / user is away
+-- Within 5 minutes of a previous nudge of any type
+-- Daily nudge limit reached

DELAY nudge when:
+-- User appears to be actively typing (suggest after a pause)
+-- User just switched contexts (wait 2 min)
+-- Within first 30 min of active hours
```

### Learning Algorithm

Simple JSON log of last 20 override events, summarized into prompt context. No ML model — Claude itself does the pattern recognition from the raw log. This is an Opus 4.6 showcase: the model's reasoning about user patterns IS the learning algorithm.

## 2.6 Data Model

### Swift Type Definitions

```swift
import Foundation
import SwiftData

// MARK: - StressEntry (core monitoring data)
@Model
final class StressEntry {
    var id: UUID
    var timestamp: Date
    var weather: String          // "clear"/"cloudy"/"stormy"
    var confidence: Double       // 0.0-1.0
    var signals: [String]
    var nudgeType: String?       // "practice"/"encouragement"/"acknowledgment"/nil
    var nudgeMessage: String?
    var suggestedPracticeID: String?
    var screenshotInterval: Int  // Seconds
}

// MARK: - PracticeSession (completed practice)
@Model
final class PracticeSession {
    var id: UUID
    var practiceID: String       // e.g., "physiological-sigh"
    var startedAt: Date
    var completedAt: Date?
    var weatherBefore: String
    var weatherAfter: String?
    var wasCompleted: Bool
    var triggeredByNudge: Bool
    var triggeringEntryID: UUID?
    var whatHelped: [String]?
}

// MARK: - DismissalEvent (AI learning data)
@Model
final class DismissalEvent {
    var id: UUID
    var timestamp: Date
    var stressEntryID: UUID
    var aiDetectedWeather: String
    var dismissalType: String    // "im_fine" / "later" / "auto_dismissed"
    var suggestedPracticeID: String?
    var contextSignals: [String]
}

// MARK: - UserPreferences
@Model
final class UserPreferences {
    var id: UUID
    var apiKey: String?                   // Claude API key (Keychain)
    var screenshotInterval: Int           // Base interval in seconds
    var activeHoursStart: Int             // Hour (0-23), default 9
    var activeHoursEnd: Int               // Hour (0-23), default 18
    var nudgeStyle: String                // "popover" / "notification" / "both"
    var soundEnabled: Bool
    var showEncouragementNudges: Bool
    var monitorActiveWindowOnly: Bool
    var preferredPracticeIDs: [String]
    var maxPracticeDuration: Int          // 60, 90, or 180
    var learnedPatterns: String?          // JSON string
}
```

### Enums (non-persisted)

```swift
enum InnerWeather: String, Codable, Sendable, CaseIterable {
    case clear, cloudy, stormy
}

enum NudgeType: String, Codable, Sendable {
    case practice, encouragement, acknowledgment
}

enum DismissalType: String, Codable, Sendable {
    case imFine, later, autoDismissed
}

struct Practice: Identifiable, Sendable {
    let id: String
    let title: String
    let category: PracticeCategory
    let duration: Int  // seconds
    let steps: [PracticeStep]
    let description: String

    enum PracticeCategory: String, Sendable {
        case breathing, body, mind
    }
}

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
```

### What We Store vs. What We Delete

| Data            | Stored | Where                | Retention              |
| --------------- | ------ | -------------------- | ---------------------- |
| Screenshots     | NEVER  | Memory only          | Deleted after API call |
| StressEntry     | Yes    | SwiftData (local)    | 30 days rolling        |
| PracticeSession | Yes    | SwiftData (local)    | Indefinite             |
| DismissalEvent  | Yes    | SwiftData (local)    | 30 days rolling        |
| UserPreferences | Yes    | SwiftData (local)    | Until user deletes     |
| API key         | Yes    | Keychain (encrypted) | Until user removes     |

## 2.7 Edge Cases

### Sensitive Content on Screen

- System prompt forbids AI from reading/quoting specific content
- AI observes patterns (tab count, notification volume), not content
- "Monitor active window only" setting reduces exposure
- Client-side filter: if nudge_message contains proper nouns/emails/URLs -> replace with generic message

### No Internet / API Failure

- Retry once after 5 seconds
- If retry fails: keep current weather icon, extend interval to 10 min, show subtle offline indicator
- Practices work fully offline

### Sleep / Wake / Screen Lock

- Screen locked: pause monitoring immediately
- Wake from sleep: wait 30 seconds, then take first screenshot
- App launch at login: check active hours, start after 60s delay if within hours

### Abandoned Practice

- Popover loses focus: practice continues in background, menu bar shows in-progress indicator
- Explicit close: save as incomplete session, no weather-after collected
- Mac goes to sleep: on wake, offer "Resume your practice?"

### AI Wrong About Stress

- User taps [I'm Fine] -> logged as override -> AI will learn
- User can manually trigger practice even when AI says "clear"
- Nudge messages never alarmist ("Busy screen. Need a moment?" not "You seem very stressed!")

### Cost Protection

- Max 100 API calls per day (hard limit)
- Warning at 80 calls
- If API key has insufficient credits -> switch to manual mode

## 2.8 Architecture Sketch

### Project Structure

```
RespiroDesktop/
+-- RespiroDesktopApp.swift          # @main, MenuBarExtra
+-- AppDelegate.swift                # NSApplicationDelegate
|
+-- Core/
|   +-- ScreenMonitor.swift          # ScreenCaptureKit, timer
|   +-- ClaudeVisionClient.swift     # API calls to Claude Opus 4.6
|   +-- NudgeEngine.swift            # Cooldown logic, smart suppression
|   +-- LearningEngine.swift         # Override pattern detection
|   +-- IntervalManager.swift        # Adaptive screenshot interval
|
+-- Models/
|   +-- StressEntry.swift            # SwiftData model
|   +-- PracticeSession.swift        # SwiftData model
|   +-- DismissalEvent.swift         # SwiftData model
|   +-- UserPreferences.swift        # SwiftData model
|   +-- InnerWeather.swift           # Enum
|   +-- Practice.swift               # Static catalog
|   +-- StressAnalysisResponse.swift # API response model
|
+-- Views/
|   +-- MenuBar/
|   +-- Onboarding/
|   +-- Nudge/
|   +-- Practice/
|   +-- Settings/
|
+-- Practices/
|   +-- PracticeCatalog.swift        # Static list of all practices
|
+-- Resources/
    +-- Assets.xcassets              # App icon, weather icons
```

### Tech Stack

| Layer        | Choice                           | Rationale                                               |
| ------------ | -------------------------------- | ------------------------------------------------------- |
| Framework    | SwiftUI + AppKit (MenuBarExtra)  | Native macOS, minimal overhead                          |
| Architecture | **@Observable + actor Services** | Architect decision: TCA overkill for single-popover app |
| Persistence  | SwiftData                        | Modern Apple stack                                      |
| Screenshot   | ScreenCaptureKit                 | Apple's modern API                                      |
| API Client   | URLSession + async/await         | No dependencies, Swift 6 native                         |
| Secrets      | Keychain Services                | API key stored securely                                 |
| Target       | macOS 14+ (Sonoma)               | ScreenCaptureKit improvements                           |
| Swift        | Swift 6                          | Strict concurrency                                      |

**Zero external dependencies** — intentional for hackathon.

### Architecture: @Observable + Services (Architect Decision)

```
AppState (@MainActor @Observable)
  |-- currentWeather: WeatherMetaphor
  |-- currentScreen: Screen (enum)
  |-- isMonitoringActive: Bool
  |-- stressHistory: [StressReading]
  |
  +-- MonitoringService (actor) — ScreenCaptureKit + timer
  +-- ClaudeVisionClient (Sendable struct) — Opus 4.6 API
  +-- NudgeEngine (actor) — cooldowns + learning
  +-- PracticeManager (@Observable) — practice flow + timer
```

Navigation = simple Screen enum (no NavigationStack in popover).

---

# Part 3: UI/UX Design Specification

## 3.1 Design Philosophy

The macOS menu bar app adapts Respiro's existing "Heritage Jade" dark theme to the macOS desktop idiom. The popup acts as a calm, non-intrusive stress companion that lives in the developer's workflow.

**Key principle:** The app should feel like a native macOS utility — quiet when idle, informative at a glance, and immersive only during active practices.

## 3.2 Menu Bar Icon — SF Symbol Weather Icons

### Concept: Recognizable Weather Icons

SF Symbol weather icons in the menu bar — immediately readable, no learning curve.

```
MENU BAR (22pt height):

  [Wi-Fi] [Battery] [ sun.max ] [Time]     <- Clear
  [Wi-Fi] [Battery] [ cloud   ] [Time]     <- Cloudy
  [Wi-Fi] [Battery] [ cloud.bolt ] [Time]  <- Stormy
```

### Three States

```
STATE 1 - CLEAR (Low Stress):
  Icon: sun.max (SF Symbol, 16pt)
  Color: Template rendering (follows system)

STATE 2 - CLOUDY (Medium Stress):
  Icon: cloud (SF Symbol, 16pt)
  Color: Template rendering

STATE 3 - STORMY (High Stress):
  Icon: cloud.bolt.rain (SF Symbol, 16pt)
  Color: Template rendering
```

### Transition Animation

When stress level changes, icon crossfades (0.3s) to new SF Symbol. Brief scale bump (1.0 -> 1.15 -> 1.0) draws attention.

## 3.3 Main Popup Layout (360x480pt)

Uses `MenuBarExtra` with `.window` style for full custom rendering.

```
+--------------------------------------------------+
|  ZONE A: Status Header (fixed, 80pt)              |
|---------------------------------------------------|
|  ZONE B: Content Area (flexible, scrollable)      |
|                                                    |
|                                                    |
|---------------------------------------------------|
|  ZONE C: Action Bar (fixed, 56pt)                 |
+--------------------------------------------------+
         360pt wide x 480pt tall
```

### Main Screen (Default State)

```
+-----------------------------------------------+
|                                                |
|   Sun  Clear Skies                  2:34 PM   |  <- Status header
|   ------------------------------------------- |
|   * * * * o o o o o o o o           Today     |  <- Mini timeline
|                                                |
|  +------------------------------------------+ |
|  |                                          | |
|  |  AI Message Card                         | |
|  |                                          | |
|  |  "Your screen time has been intense      | |
|  |   for 90 min. A 2-minute breathing       | |
|  |   break could help reset your focus."    | |
|  |                                          | |
|  |               [Got it]                   | |
|  +------------------------------------------+ |
|                                                |
|  +--------------+  +---------------------+    |
|  | Last check-in|  | Streak              |    |  <- Stats row
|  | Cloudy -> Sun|  | 5 days              |    |
|  +--------------+  +---------------------+    |
|                                                |
|  ============================================= |
|                                                |
|  [ Start Practice ]              [Settings]    |  <- Action bar
|                                                |
+-----------------------------------------------+
```

### Layout Specifications

- **Popup container:** 360x480pt, background #0A1F1A, corner radius 12pt
- **Zone A (80pt):** Weather icon 32pt, status text 16pt semibold, mini timeline with 12 hourly dots
- **Zone B (scrollable):** 16pt padding, 12pt card spacing
- **Zone C (56pt):** Primary button jade green, settings gear icon

## 3.4 Practice Flow Screens (4 Screens)

All practice screens render inside the same 360x480pt popup.

### Screen 1: Weather Picker (Before)

Three weather cards (96x112pt each) in a horizontal row:

- Clear (sun), Cloudy (cloud), Stormy (storm)
- Selected state: 2pt jade green border, 8% jade background
- Hover: subtle 1.02x scale lift

### Screen 2: Practice In Progress (Breathing Animation)

- Breathing circle: 160x160pt, radial gradient jade green
- Inhale: scale 0.6 -> 1.0
- Exhale: scale 1.0 -> 0.6
- Hold: gentle opacity pulse
- Phase label: 16pt medium, letter-spacing 4pt
- Progress dots: 16 dots (one per breath cycle)
- Timer: "2:15 remaining"

### Screen 3: Weather Picker (After)

Same layout as Screen 1, title: "How do you feel now?"
Previously selected weather shown dimmed (30% opacity) as reference.

### Screen 4: Completion / Celebration

- Animated checkmark (circle scales in -> checkmark draws -> glow pulse)
- Delta badge: weather before -> arrow -> weather after
- Science snippet: 13pt italic, max 3 lines

## 3.5 AI Message Card Styles

Four visual variants differentiated by accent color and icon:

| Style        | Accent Color         | Icon        | Left Border   |
| ------------ | -------------------- | ----------- | ------------- |
| Urgent       | Muted Purple #7B6B9E | bolt.fill   | 3pt purple    |
| Reassuring   | Blue-Gray #8BA4B0    | cloud.fill  | 3pt blue-gray |
| Gentle Nudge | Jade Green #10B981   | drop.fill   | 3pt jade      |
| Celebration  | Premium Gold #D4AF37 | trophy.fill | 3pt gold      |

**Shared specs:** Surface background (white 8%), 12pt radius, 16pt padding, fade in + slide up 8pt entry animation. Max 1 card visible at a time.

## 3.6 Color Palette — macOS Adaptation

### Primary Palette

```
BACKGROUNDS:
  Popup Background:    #0A1F1A
  Surface:             rgba(199, 232, 222, 0.08)
  Surface Hover:       rgba(199, 232, 222, 0.12)

TEXT:
  Primary:             rgba(224, 244, 238, 0.92)
  Secondary:           rgba(224, 244, 238, 0.84)
  Tertiary:            rgba(224, 244, 238, 0.60)

ACCENTS:
  Jade Green:          #10B981  — buttons, breathing, success
  Blue-Gray:           #8BA4B0  — cloudy weather, reassuring
  Muted Purple:        #7B6B9E  — stormy weather, urgent
  Premium Gold:        #D4AF37  — celebrations, streaks

BORDERS:
  Default:             rgba(192, 224, 214, 0.10)
  Selected:            #10B981 at 60% opacity
```

### Contrast (WCAG AA Verified)

- Text Primary on Background: ~12:1 (PASS AAA)
- Text Secondary: ~9:1 (PASS AAA)
- Text Tertiary: ~5:1 (PASS AA)
- Jade Green on Background: ~6:1 (PASS AA)

## 3.7 Navigation Flow

```
MENU BAR CLICK
    |
    v
MAIN POPUP (default)
    |
    +-- [Start Practice] --> WEATHER BEFORE --> PRACTICE --> WEATHER AFTER --> COMPLETION --> MAIN
    |
    +-- [Settings] --> SETTINGS PANEL
    |
    +-- Click outside --> Popup dismisses
```

All screens use horizontal slide transition (0.25s ease-in-out).

## 3.8 macOS-Specific Interaction Patterns

### Hover States

Every interactive element has a hover state:

- Buttons: brightness +8% on hover, +15% on press
- Cards: background opacity 8% -> 12% on hover
- Weather cards: subtle 1.02x scale

### Keyboard Shortcuts

| Shortcut    | Action                               |
| ----------- | ------------------------------------ |
| Cmd+Shift+R | Toggle popup (global hotkey)         |
| Escape      | Close popup / go back                |
| Return      | Primary action (Continue, Done)      |
| 1/2/3       | Select weather (Clear/Cloudy/Stormy) |
| Space       | Pause/resume during practice         |

### Dark Mode

App always uses dark appearance (enforced via `.preferredColorScheme(.dark)`).

## 3.9 Component Reuse from iOS

| iOS Component  | macOS Usage                   | Adaptation    |
| -------------- | ----------------------------- | ------------- |
| `WeatherIcon`  | Weather picker, status header | size: 32-40pt |
| `DeltaBadge`   | Completion screen             | Reuse as-is   |
| `InnerWeather` | Data model                    | Reuse as-is   |
| `BreathPhase`  | Practice timing               | Reuse as-is   |

**New macOS-native components needed:** Breathing animation (SwiftUI only, no Metal), navigation (state-driven swap, no NavigationStack), cards (hover states), buttons (keyboard shortcuts).

## 3.10 Accessibility

- All animations respect `accessibilityReduceMotion`
- Menu bar icon has accessible label: "Respiro - [Current Weather State]"
- Weather picker cards: `.button` accessible role
- Breathing phase label: `.updatesFrequently`
- Minimum click target: 24x24pt (macOS standard)
- All text meets WCAG AA contrast
- VoiceOver announces AI message cards as notifications
- Full keyboard navigation via Tab

---

# Appendix: Opus 4.6 Showcase Summary

| Capability              | Product Feature                   | Demo Moment                                              |
| ----------------------- | --------------------------------- | -------------------------------------------------------- |
| **Vision API**          | Screenshot stress analysis        | Icon changes in real-time                                |
| **Adaptive Thinking**   | When to interrupt vs. stay silent | "AI chose not to interrupt during flow state"            |
| **Tool Use**            | Practice selection from history   | "Selected body scan because your completion rate is 90%" |
| **Context Window (1M)** | End-of-day reflection             | Full day synthesized into personalized insights          |
| **Structured Output**   | Reliable JSON parsing             | Every analysis returns valid, parseable data             |
| **Safety/Alignment**    | Never reads private content       | Privacy-first design judges appreciate                   |

---

_PRD assembled from: Founder Strategy (founder-1), Product Specs (po-1), UI/UX Design (designer-1)_
_Agent Team: prd-team | February 10, 2026_
