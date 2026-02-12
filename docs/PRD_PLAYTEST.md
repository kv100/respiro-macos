# Respiro Playtest — PRD

**AI-Powered Self-Evolving Testing for Respiro macOS**
**Hackathon:** "Built with Opus 4.6" (Feb 10-16, 2026)
**Date:** 2026-02-11

---

## 1. What Is Playtest?

An in-app AI testing system that:

1. Runs **seed scenarios** through Respiro's real decision logic
2. Uses Opus 4.6 to **evaluate** whether behavior matches expectations
3. **Generates new scenarios** based on what it discovered — edge cases, boundary conditions, unexplored paths
4. Runs the new scenarios, evaluates again, and keeps exploring

**One sentence:** "Opus 4.6 tests itself, finds its own blind spots, and invents new tests to cover them — an AI exploration loop."

### What Makes This Different From Regular Tests?

| Traditional Testing           | Playtest                                     |
| ----------------------------- | -------------------------------------------- |
| Human writes test cases       | AI writes AND expands test cases             |
| Static — same tests every run | Self-evolving — each run discovers new tests |
| Pass/fail assertions          | AI reasons about correctness + UX quality    |
| Finds what you test for       | Finds what you **didn't think to test**      |
| Coverage is manual            | Coverage grows automatically                 |

### The Exploration Loop

```
Round 1: 8 seed scenarios → run → evaluate
    ↓
Opus analyzes results: "Cooldown boundary at 30min is untested.
What happens at 29min? 31min? What about cooldown + dismissal combo?"
    ↓
Round 2: +4 AI-generated scenarios → run → evaluate
    ↓
Opus: "Found edge case: practice completed at exactly daily limit.
What if user completes practice AND hits limit simultaneously?"
    ↓
Round 3: +2 more scenarios → run → evaluate → confidence 94%
    ↓
STOP: confidence threshold reached or max rounds hit
```

**Output:** A growing behavioral map of the app — what works, what's fragile, what the AI discovered that we never thought to test.

---

## 2. Why Build This?

### 2.1 Hackathon Value

| Judging Criteria (weight)   | How Playtest Helps                                                                             |
| --------------------------- | ---------------------------------------------------------------------------------------------- |
| **Impact (25%)**            | Self-evolving AI testing = higher reliability = more trust = real impact                       |
| **Opus 4.6 Use (25%)**      | Triple showcase: evaluation + generation + exploration loop. Extended Thinking at every stage. |
| **Depth & Execution (20%)** | Engineering sophistication — not just AI testing, but AI that **invents its own tests**        |
| **Demo (30%)**              | "Started with 8 tests, AI generated 6 more, found 2 edge cases we missed" = unforgettable demo |

### 2.2 Competitive Edge

Other hackathon entries use Opus 4.6 as a tool. We build an **AI exploration loop** where Opus 4.6:

- **Evaluates** its own decisions (meta-cognition)
- **Hypothesizes** about untested edge cases (scientific reasoning)
- **Designs experiments** to test those hypotheses (scenario generation)
- **Learns** from results and generates more hypotheses (exploration loop)

This is the closest thing to **AI self-improvement** you can build in a hackathon — and it's practical, not theoretical.

### 2.3 Special Prize Angles

- **"Most Creative Opus 4.6 Exploration" ($5k)** — literally an exploration loop. AI explores its own behavior space.
- **"Keep Thinking" ($5k)** — AI thinks hard at every stage: evaluating, hypothesizing, generating. The loop IS extended thinking.

---

## 3. User Experience

### 3.1 Entry Point

Settings screen -> "Playtest" section -> "Run Exploration" button -> navigates to Playtest screen.

### 3.2 Playtest Screen (360x480pt popover)

```
+--------------------------------------------------+
| [< Back]           PLAYTEST        [Explore]      |
+--------------------------------------------------+
| ROUND 1 — Seed Scenarios (8)                      |
|  SC-1  Sustained focus        PASSED  92%  ✅     |
|  SC-2  Stress escalation      PASSED  88%  ✅     |
|  SC-3  Dismissal cooldown     PASSED  85%  ✅     |
|  SC-4  Practice completion    PASSED  90%  ✅     |
|  SC-5  Smart suppression      PASSED  87%  ✅     |
|  SC-6  Nudge interval         FAILED  62%  ⚠️     |
|  SC-7  Manual practice        PASSED  91%  ✅     |
|  SC-8  Daily limit            PASSED  88%  ✅     |
+--------------------------------------------------+
| ROUND 2 — AI-Generated (4)                  🤖    |
|  SC-9  Boundary: 29min nudge  PASSED  85%  ✅     |
|  SC-10 Boundary: 31min nudge  PASSED  83%  ✅     |
|  SC-11 Dismiss + practice     RUNNING...   ⏳     |
|  SC-12 Rapid dismiss chain    PENDING      ⏸     |
+--------------------------------------------------+
| Round 2/3 · Generating hypotheses...              |
| [████████████░░░░░░░] 11/12                       |
+--------------------------------------------------+
```

### 3.3 Scenario Detail (tap any scenario)

```
+--------------------------------------------------+
| SC-10: Boundary 31min Nudge              PASSED   |
| 🤖 AI-Generated (Round 2)                         |
+--------------------------------------------------+
| HYPOTHESIS:                                       |
|  "SC-6 showed nudge interval issues at 10min.    |
|   Testing boundary at exactly 31min (just past   |
|   30-min minimum) to verify correct behavior."   |
+--------------------------------------------------+
| EXPECTED:                                         |
|  • Nudge allowed after 31 minutes                |
| ACTUAL:                                           |
|  • Nudge correctly shown at 31 minutes ✅         |
+--------------------------------------------------+
| AI ANALYSIS:                                      |
|  brain.head.profile  Effort: ●●○ HIGH            |
|  "The 31-minute boundary works correctly.        |
|   Combined with SC-6's failure at 10min, this    |
|   confirms the minimum interval is enforced      |
|   but the boundary itself is clean."             |
+--------------------------------------------------+
```

### 3.4 Summary (after exploration complete)

```
+--------------------------------------------------+
|          EXPLORATION COMPLETE                      |
|                                                   |
|  3 rounds · 14 total scenarios                    |
|  8 seed + 6 AI-generated                          |
|                                                   |
|  13/14 PASSED     1 FAILED                        |
|  Overall confidence: 91%                          |
+--------------------------------------------------+
| AI Summary:                                       |
| "Explored 14 scenarios across 3 rounds. The app  |
|  correctly handles core flows and boundary cases. |
|  One issue: nudge interval check at exactly       |
|  10 min should block but doesn't (SC-6). AI      |
|  generated 6 follow-up tests around this area,   |
|  confirming the boundary at 30+ min is correct.  |
|  Recommendation: fix the < vs <= comparison in   |
|  minAnyNudgeInterval check."                     |
+--------------------------------------------------+
| Discoveries:                                      |
|  🔍 6 new edge cases tested                       |
|  🐛 1 boundary bug confirmed                      |
|  ✅ 5 hypotheses validated                         |
+--------------------------------------------------+
| [Explore Again]    [Back to Settings]             |
+--------------------------------------------------+
```

---

## 4. How It Works (Architecture)

### 4.1 Exploration Loop

```
PlaytestService (Orchestrator)
    |
    +-- ROUND 1: Seed Scenarios
    |     |
    |     +-- For each of 8 seed scenarios:
    |     |     +-- ScenarioRunner.execute(scenario) → PlaytestResult
    |     |     +-- ResultEvaluator.evaluate(scenario, result) → ScenarioEvaluation
    |     |
    |     +-- All done? → ScenarioGenerator.generateNext(allResults)
    |
    +-- ROUND 2: AI-Generated Scenarios
    |     |
    |     +-- ScenarioGenerator calls Opus 4.6:
    |     |     "Here are the results of 8 tests. Here are the app's rules.
    |     |      What edge cases should I test next? Generate 3-5 new scenarios."
    |     |
    |     +-- Opus returns new PlaytestScenario definitions (JSON)
    |     |
    |     +-- For each generated scenario:
    |     |     +-- ScenarioRunner.execute → PlaytestResult
    |     |     +-- ResultEvaluator.evaluate → ScenarioEvaluation
    |     |
    |     +-- confidence >= 90% OR max rounds? → STOP
    |     +-- else → ScenarioGenerator.generateNext(allResults) → ROUND 3
    |
    +-- FINAL: Generate PlaytestReport (aggregate all rounds)
```

### 4.2 Components

| Component             | Type                   | Role                                                   |
| --------------------- | ---------------------- | ------------------------------------------------------ |
| **PlaytestService**   | @MainActor @Observable | Orchestrates exploration loop, streams progress to UI  |
| **ScenarioRunner**    | actor                  | Executes scenarios against fresh NudgeEngine instances |
| **ResultEvaluator**   | Sendable struct        | Calls Opus 4.6 to evaluate each scenario result        |
| **ScenarioGenerator** | Sendable struct        | Calls Opus 4.6 to generate new scenarios from results  |
| **PlaytestCatalog**   | static                 | 8 seed scenarios (hardcoded starting point)            |

### 4.3 Key Design Decisions

1. **Tests run against real NudgeEngine logic** — not mocks. Fresh instance per scenario, real bug detection.

2. **No screenshots needed** — mock `StressAnalysisResponse` objects (same pattern as DemoModeService). Testing the decision layer, not Vision API.

3. **AI evaluates AND generates** — Opus reasons about correctness, then reasons about what to test next. Two different thinking modes.

4. **Exploration has bounds** — max 3 rounds, max 5 new scenarios per round, confidence threshold 90%. Prevents infinite loops and API cost explosion.

5. **State isolation** — fresh NudgeEngine per scenario. No cross-contamination.

6. **Generated scenarios are first-class** — same `PlaytestScenario` struct as seed scenarios. Runner and evaluator don't know the difference.

---

## 5. Scenario Catalog

### 5.1 Seed Scenarios (8, hardcoded)

| ID   | Name                | What It Tests                       | Steps                               | Expected Outcome                              |
| ---- | ------------------- | ----------------------------------- | ----------------------------------- | --------------------------------------------- |
| SC-1 | Sustained Focus     | Adaptive interval, silence decision | 3x clear weather, no user action    | No nudges, interval increases to 15min        |
| SC-2 | Stress Escalation   | Nudge threshold, practice selection | clear -> cloudy -> stormy           | Practice nudge on stormy, breathing suggested |
| SC-3 | Dismissal Cooldown  | Cooldown after 3 dismissals         | stormy + 3x "I'm Fine"              | 2-hour silence cooldown, no nudges            |
| SC-4 | Practice Completion | Post-practice cooldown              | stormy -> practice -> clear         | 45-min post-practice cooldown respected       |
| SC-5 | Smart Suppression   | Video call detection                | cloudy + video call signals         | Nudge suppressed, silence decision logged     |
| SC-6 | Rapid Storms        | Minimum nudge interval              | stormy -> 10min -> stormy           | Second nudge blocked (30-min minimum)         |
| SC-7 | Manual Practice     | Practice without nudge              | user starts practice during "clear" | Session logged, no weather change required    |
| SC-8 | Daily Limit         | Max daily practice nudges           | 7 stormy entries in one day         | 6th practice nudge shown, 7th blocked         |

### 5.2 AI-Generated Scenarios (examples of what Opus might create)

These are **not hardcoded** — Opus generates them dynamically based on Round 1 results:

| Example                      | Why Opus Generates It                                                               |
| ---------------------------- | ----------------------------------------------------------------------------------- |
| "Cooldown boundary at 29min" | SC-6 tested 10min interval; AI tests the exact boundary at 30min                    |
| "Dismissal then practice"    | SC-3 tested dismissals, SC-4 tested practice; AI tests the combination              |
| "5 dismissals in 1 hour"     | SC-3 tested 3 dismissals; AI tests what happens beyond the threshold                |
| "Stormy -> clear -> stormy"  | SC-2 tested escalation; AI tests de-escalation then re-escalation                   |
| "Practice at daily limit"    | SC-8 tested daily limit; AI tests edge case of completing practice exactly at limit |

---

## 6. Opus 4.6 Integration

### 6.1 Evaluation Prompt (per scenario)

```
You are evaluating a stress-coaching AI app's behavior.
The app uses weather metaphors (clear/cloudy/stormy) and decides
when to nudge users with stress-relief practices.

SCENARIO: {scenario.name}
DESCRIPTION: {scenario.description}

EXPECTED BEHAVIOR:
{scenario.expectedBehavior formatted as bullet points}

ACTUAL BEHAVIOR:
{result.actualBehavior formatted as bullet points}

STEP-BY-STEP TRACE:
{result.stepTrace — what happened at each step}

Analyze whether the app's behavior is correct. Consider:
1. Did the nudge logic match expectations?
2. Were cooldowns applied correctly?
3. Would this behavior feel natural to a user?
4. Are there edge cases or subtle bugs?

Respond with JSON:
{
  "passed": true/false,
  "confidence": 0.0-1.0,
  "reasoning": "plain English analysis",
  "mismatches": ["specific difference 1", ...],
  "suggestions": ["improvement idea 1", ...]
}
```

- `thinking.type: "enabled"`, `budget_tokens: 4096`
- Effort: `.high`

### 6.2 Scenario Generation Prompt (after each round)

```
You are an AI testing specialist analyzing a stress-coaching app called Respiro.
The app monitors user stress via weather metaphors and decides when to nudge with practices.

APP RULES:
- minPracticeInterval: 30 min between practice nudges
- minAnyNudgeInterval: 10 min between any nudge
- postDismissalCooldown: 15 min
- consecutiveDismissalCooldown: 2 hours (after 3 dismissals)
- postPracticeCooldown: 45 min
- maxDailyPracticeNudges: 6
- maxDailyTotalNudges: 12
- Confidence >= 0.6 required for practice nudge
- Smart suppression: skip nudge during video calls, presentations

SCENARIOS TESTED SO FAR:
{all scenarios with their evaluations as JSON}

FINDINGS:
- Passed: {list}
- Failed: {list with reasoning}
- Confidence gaps: {scenarios with < 80% confidence}

Based on these results, generate 3-5 NEW test scenarios that:
1. Test BOUNDARY CONDITIONS around rules (exact time thresholds, counts at limits)
2. Test COMBINATIONS of behaviors not yet tested together
3. Probe areas where confidence was LOW
4. Explore SEQUENCES not covered (e.g., dismiss -> practice -> dismiss)
5. Each scenario should have a HYPOTHESIS explaining why it might reveal a bug

For each scenario, provide:
{
  "scenarios": [
    {
      "id": "sc-N",
      "name": "short name",
      "hypothesis": "Why this test might reveal a bug",
      "description": "What this scenario tests",
      "steps": [
        {
          "id": "Na",
          "description": "step description",
          "weather": "clear|cloudy|stormy",
          "confidence": 0.0-1.0,
          "signals": ["signal1", "signal2"],
          "nudge_type": "practice|encouragement|null",
          "nudge_message": "message or null",
          "practice_id": "id or null",
          "user_action": "dismiss_im_fine|dismiss_later|start_practice|complete_practice|null",
          "time_delta": seconds_since_last_step
        }
      ],
      "expected_behavior": ["expected outcome 1", ...]
    }
  ]
}
```

- `thinking.type: "enabled"`, `budget_tokens: 10240` (max effort for deep hypothesis generation)
- This is the **core showcase** — AI literally designing its own experiments

### 6.3 Summary Prompt (final)

```
You explored a stress-coaching AI app's behavior across {N} rounds and {M} total scenarios.

COMPLETE RESULTS:
{all evaluations grouped by round}

Write an exploration report:
1. Overall app quality assessment
2. What the exploration discovered (edge cases, boundaries)
3. Seed scenarios vs AI-generated: which found more issues?
4. Confidence trajectory across rounds (did confidence increase?)
5. Remaining untested areas (what would Round N+1 test?)

Respond with JSON:
{
  "overall_passed": true/false,
  "overall_confidence": 0.0-1.0,
  "summary": "3-4 sentence assessment",
  "discoveries": ["discovery 1", ...],
  "critical_issues": ["issue 1", ...],
  "strengths": ["strength 1", ...],
  "untested_areas": ["area 1", ...],
  "confidence_trajectory": [round1_conf, round2_conf, ...]
}
```

- `thinking.type: "enabled"`, `budget_tokens: 10240` (max effort)

---

## 7. Demo Integration (30% of Judging)

### 7.1 Demo Video Segment (45-60 seconds)

**Script:**

> "But the most interesting part? The app tests itself — and invents its own tests."
>
> [Show playtest screen, tap "Explore"]
>
> "We start with 8 seed scenarios covering core flows — stress detection, cooldowns, suppression."
>
> [Round 1 runs, checkmarks appear]
>
> "Round 1: 7 of 8 pass. One nudge interval issue found."
>
> [Show "Generating hypotheses..." with thinking animation]
>
> "Now Opus 4.6 thinks: 'The 10-minute interval failed. What about the boundary at 30 minutes? What about combining dismissals with practice completion?'"
>
> [Round 2 scenarios appear with robot icon]
>
> "It generated 4 new tests we never thought of. Round 2 runs..."
>
> [Checkmarks appear for AI-generated tests]
>
> "14 total scenarios, 3 rounds, 91% confidence. The AI found its own blind spots and tested them."
>
> [Show summary with discoveries]
>
> "This isn't testing. This is an AI exploration loop — Opus 4.6 investigating its own intelligence."

### 7.2 Why Judges Will Remember This

- **Self-evolving** — AI doesn't just run tests, it invents new ones
- **Scientific method** — hypothesis -> experiment -> analysis -> new hypothesis
- **Practical** — actually discovers real bugs through exploration
- **Meta-cognition squared** — AI testing AI, then thinking about what else to test
- **Unique** — nobody else in the hackathon will have this

---

## 8. Scope & Constraints

### In Scope

- 8 seed scenarios (hardcoded starting point)
- Exploration loop: up to 3 rounds, 3-5 new scenarios per round
- In-app UI with round grouping and hypothesis display
- Opus 4.6 evaluation + generation with Extended Thinking
- Per-scenario detail with AI reasoning + hypothesis
- Summary with discoveries and confidence trajectory

### Exploration Bounds

- **Max rounds:** 3 (seed + 2 AI-generated)
- **Max new scenarios per round:** 5
- **Max total scenarios:** 8 + 5 + 5 = 18
- **Confidence stop:** if overall >= 90% after a round, stop
- **Timeout:** 3 minutes total (for demo reliability)

### Out of Scope (Post-Hackathon)

- CLI mode / CI integration
- Persistent exploration history across sessions
- Custom seed scenario editor in UI
- Automated fix suggestions (Opus suggests code changes)
- Screenshot-based visual regression testing

### API Cost

- Round 1: 8 evaluations = 8 calls
- Generation: 1 call per round = 1-2 calls
- Round 2-3: 3-10 evaluations = 3-10 calls
- Summary: 1 call
- **Total: ~13-21 Opus calls per exploration (~$1-3)**
- Demo mode: cache results after first exploration

### Implementation Estimate

- Core logic (models + runner + evaluator): ~4h
- ScenarioGenerator (new): ~2h
- Exploration loop in PlaytestService: ~1.5h
- UI (views with round grouping): ~3h
- Integration: ~1h
- **Total: ~11.5h**

---

## 9. Risk Assessment

| Risk                                    | Mitigation                                                                          |
| --------------------------------------- | ----------------------------------------------------------------------------------- |
| Generated scenarios are invalid/broken  | Validate JSON schema. Fallback: skip invalid, continue with valid.                  |
| Exploration loop runs too long for demo | Max 3 rounds, 3-min timeout. Cache results for demo video.                          |
| AI generates redundant scenarios        | Prompt includes all previous scenarios. Opus avoids duplicates by seeing full list. |
| API cost per exploration too high       | Bounds: max 18 scenarios, max 21 API calls. ~$1-3 per run is acceptable.            |
| Evaluation accuracy inconsistent        | Extended Thinking + detailed prompts. Confidence scores flag uncertainty.           |
| Generated scenarios don't find bugs     | Even if all pass, the exploration itself is the demo. "AI confirmed correctness."   |

---

## 10. The Output: What "Learning" Produces

The exploration doesn't train a model, but it produces a **behavioral knowledge graph**:

1. **Scenario Coverage Map** — what behaviors are tested, what isn't
2. **Confidence Scores** — per scenario and overall, increasing with each round
3. **Edge Case Catalog** — AI-discovered boundary conditions
4. **Bug Reports** — specific mismatches with reasoning and suggested fixes
5. **Hypothesis Trail** — why the AI thought each test was worth running
6. **Untested Areas** — what the next exploration round would investigate

This is the output a developer gets after each exploration — not weights or gradients, but **understanding**.
