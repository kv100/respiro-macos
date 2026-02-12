# Respiro Playtest — Backlog

> Hackathon: "Built with Opus 4.6" | Feb 10-16, 2026
> Full PRD: `docs/PRD_PLAYTEST.md` | Architecture: @Observable + actor Services
> Main backlogs: `docs/BACKLOG.md` (V1), `docs/BACKLOG_V2.md` (V2)

---

## Task List

| ID   | Task                                                                     | Est  | Agent           | Depends    | Status |
| ---- | ------------------------------------------------------------------------ | ---- | --------------- | ---------- | ------ |
| PT.1 | Data models — PlaytestScenario, PlaytestResult, ScenarioEvaluation       | 1.5h | swift-developer | —          | todo   |
| PT.2 | Seed scenario catalog — 8 scenarios with steps + expected outcomes       | 1.5h | swift-developer | PT.1       | todo   |
| PT.3 | ScenarioRunner actor — execute scenarios against fresh NudgeEngine       | 2h   | swift-developer | PT.1       | todo   |
| PT.4 | ResultEvaluator — call Opus 4.6 with Extended Thinking for evaluation    | 2h   | swift-developer | PT.1       | todo   |
| PT.5 | ScenarioGenerator — call Opus 4.6 to generate new scenarios from results | 2h   | swift-developer | PT.1       | todo   |
| PT.6 | PlaytestService — exploration loop, rounds, progress, report             | 2h   | swift-developer | PT.3-PT.5  | todo   |
| PT.7 | PlaytestView — scenario list with rounds, live runner, summary           | 2.5h | swiftui-pro     | PT.6       | todo   |
| PT.8 | ScenarioDetailView — hypothesis, expected vs actual, AI analysis         | 1.5h | swiftui-pro     | PT.7       | todo   |
| PT.9 | Integration — AppState.Screen.playtest, Settings button, navigation      | 1h   | swift-developer | PT.6, PT.7 | todo   |

**Total: ~16h**

---

## Dependencies

```
PT.1 (models)
  ├── PT.2 (seed catalog) ─────────────────────────────┐
  ├── PT.3 (runner) ──────┐                             │
  ├── PT.4 (evaluator) ──┤                             │
  └── PT.5 (generator) ──┤                             │
                          ├── PT.6 (service + loop) ────┤
                          │                             ├── PT.9 (integration)
                          │   PT.7 (views) ─────────────┤
                          │     └── PT.8 (detail view)  │
```

**Parallel work possible:**

- PT.2, PT.3, PT.4, PT.5 can run in parallel (all depend only on PT.1)
- PT.7 + PT.8 can start once PT.6 interface is defined

---

## Architecture & File Structure

```
RespiroDesktop/
├── Core/
│   ├── PlaytestService.swift       # @MainActor @Observable — exploration loop orchestrator
│   ├── ScenarioRunner.swift        # actor — executes scenarios against NudgeEngine
│   ├── ResultEvaluator.swift       # Sendable struct — Opus 4.6 evaluation calls
│   └── ScenarioGenerator.swift     # Sendable struct — Opus 4.6 generates new scenarios
├── Models/
│   ├── PlaytestModels.swift        # PlaytestScenario, PlaytestResult, ScenarioEvaluation, PlaytestReport
│   └── PlaytestCatalog.swift       # 8 seed scenario definitions
└── Views/
    └── Playtest/
        ├── PlaytestView.swift      # Main screen: rounds, scenario list, runner, summary
        └── ScenarioDetailView.swift # Per-scenario: hypothesis, expected/actual, AI analysis
```

**Files to modify:**

- `Core/AppState.swift` — add `.playtest` to Screen enum, add PlaytestService ref
- `Views/MainView.swift` — add PlaytestView case to switch
- `Views/Settings/SettingsView.swift` — add "Playtest" section with button

---

## Agent Specs — Data Models (PT.1)

```swift
// MARK: - Scenario Step

struct ScenarioStep: Sendable, Identifiable {
    let id: String
    let description: String
    let mockAnalysis: StressAnalysisResponse
    let userAction: PlaytestUserAction?  // nil = no user action
    let timeDelta: TimeInterval          // seconds since previous step
}

enum PlaytestUserAction: String, Sendable, Codable {
    case dismissImFine
    case dismissLater
    case startPractice
    case completePractice
}

// MARK: - Scenario

struct PlaytestScenario: Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let steps: [ScenarioStep]
    let round: Int                      // 1 = seed, 2+ = AI-generated

    // Expected outcomes (human-readable for AI evaluation)
    let expectedBehavior: [String]

    // AI-generated scenarios include a hypothesis
    let hypothesis: String?             // nil for seed scenarios

    // Machine-checkable assertions (optional, pre-AI quick check)
    let assertions: [PlaytestAssertion]
}

struct PlaytestAssertion: Sendable {
    let stepID: String
    let field: AssertionField
    let expected: String

    enum AssertionField: String, Sendable {
        case nudgeShouldShow     // "true" / "false"
        case nudgeType           // "practice" / "encouragement" / nil
        case cooldownActive      // "true" / "false"
    }
}

// MARK: - Result

struct PlaytestResult: Sendable {
    let scenarioID: String
    let stepResults: [StepResult]
    let totalDuration: TimeInterval

    struct StepResult: Sendable, Identifiable {
        let id: String
        let nudgeDecision: NudgeDecision
        let cooldownState: CooldownSnapshot
        let timestamp: Date
    }

    struct CooldownSnapshot: Sendable {
        let consecutiveDismissals: Int
        let dailyNudgeCount: Int
        let dailyPracticeNudgeCount: Int
        let isInCooldown: Bool
        let cooldownReason: String?
    }
}

// MARK: - Evaluation

struct ScenarioEvaluation: Codable, Sendable {
    let scenarioID: String
    let passed: Bool
    let confidence: Double          // 0.0-1.0
    let reasoning: String
    let mismatches: [String]
    let suggestions: [String]
    let thinkingText: String?       // Extended Thinking trace

    /// Error factory
    static func error(scenarioID: String, message: String) -> ScenarioEvaluation {
        ScenarioEvaluation(
            scenarioID: scenarioID, passed: false, confidence: 0,
            reasoning: "Error: \(message)", mismatches: [], suggestions: [],
            thinkingText: nil
        )
    }
}

// MARK: - Report

struct PlaytestReport: Sendable {
    let rounds: [PlaytestRound]
    let overallPassed: Bool
    let overallConfidence: Double
    let summary: String
    let discoveries: [String]           // what the exploration found
    let criticalIssues: [String]
    let strengths: [String]
    let untestedAreas: [String]         // what Round N+1 would test
    let confidenceTrajectory: [Double]  // confidence per round
    let thinkingText: String?
    let completedAt: Date
}

struct PlaytestRound: Sendable, Identifiable {
    let id: Int                         // round number (1, 2, 3)
    let scenarios: [PlaytestScenario]
    let evaluations: [ScenarioEvaluation]
    let isAIGenerated: Bool             // false for round 1 (seed)
}
```

---

## Agent Specs — Seed Catalog (PT.2)

### SC-1: Sustained Focus

```swift
PlaytestScenario(
    id: "sc-1", name: "Sustained Focus", round: 1, hypothesis: nil,
    description: "3 consecutive clear readings with no interaction. App should stay silent.",
    steps: [
        ScenarioStep(id: "1a", description: "Clear, focused work",
            mockAnalysis: .clear(confidence: 0.88, signals: ["single app focused", "clean desktop"]),
            userAction: nil, timeDelta: 0),
        ScenarioStep(id: "1b", description: "Still clear, coding",
            mockAnalysis: .clear(confidence: 0.85, signals: ["code editor active", "steady typing"]),
            userAction: nil, timeDelta: 300),
        ScenarioStep(id: "1c", description: "Clear, organized workspace",
            mockAnalysis: .clear(confidence: 0.90, signals: ["organized tabs", "low notification count"]),
            userAction: nil, timeDelta: 300),
    ],
    expectedBehavior: [
        "No practice nudges shown on any step",
        "Encouragement nudge possible but not required",
    ],
    assertions: [
        PlaytestAssertion(stepID: "1a", field: .nudgeShouldShow, expected: "false"),
        PlaytestAssertion(stepID: "1b", field: .nudgeShouldShow, expected: "false"),
        PlaytestAssertion(stepID: "1c", field: .nudgeShouldShow, expected: "false"),
    ]
)
```

### SC-2: Stress Escalation

```swift
PlaytestScenario(
    id: "sc-2", name: "Stress Escalation", round: 1, hypothesis: nil,
    description: "Weather clear → cloudy → stormy. App should suggest practice on stormy.",
    steps: [
        ScenarioStep(id: "2a", description: "Clear morning",
            mockAnalysis: .clear(confidence: 0.85, signals: ["clean inbox"]),
            userAction: nil, timeDelta: 0),
        ScenarioStep(id: "2b", description: "Cloudy after meetings",
            mockAnalysis: .cloudy(confidence: 0.72, signals: ["multiple tabs", "calendar full"]),
            userAction: nil, timeDelta: 600),
        ScenarioStep(id: "2c", description: "Stormy — overload",
            mockAnalysis: .stormy(confidence: 0.82, signals: ["47 unread messages", "rapid tab switching"],
                nudge: .practice, message: "Things look intense. Try a quick breathing exercise?",
                practiceID: "physiological-sigh"),
            userAction: nil, timeDelta: 600),
    ],
    expectedBehavior: [
        "No nudge on clear (step 2a)",
        "No practice nudge on cloudy (step 2b)",
        "Practice nudge shown on stormy (step 2c)",
        "Breathing practice suggested (stormy + high confidence)",
    ],
    assertions: [
        PlaytestAssertion(stepID: "2a", field: .nudgeShouldShow, expected: "false"),
        PlaytestAssertion(stepID: "2c", field: .nudgeShouldShow, expected: "true"),
        PlaytestAssertion(stepID: "2c", field: .nudgeType, expected: "practice"),
    ]
)
```

### SC-3 through SC-8 (condensed descriptions)

**SC-3: Dismissal Cooldown** — 3 consecutive "I'm Fine" dismissals on stormy → 2h cooldown. 4th stormy should NOT trigger nudge.

**SC-4: Practice Completion** — Stormy → practice suggested → user completes → 45-min cooldown. Next stormy within 45min blocked.

**SC-5: Smart Suppression** — Cloudy weather but signals include "video call active" → nudge suppressed.

**SC-6: Rapid Storms** — Two stormy readings 10 min apart. First triggers nudge, second blocked (30-min minimum).

**SC-7: Manual Practice** — User starts practice during "clear" weather. Session logged, no weather change needed.

**SC-8: Daily Limit** — 7 stormy entries across a day. Practice nudges 1-6 shown, 7th blocked (max 6).

**Implementation note:** Each scenario needs convenience initializers on StressAnalysisResponse:

```swift
extension StressAnalysisResponse {
    static func clear(confidence: Double, signals: [String]) -> StressAnalysisResponse { ... }
    static func cloudy(confidence: Double, signals: [String]) -> StressAnalysisResponse { ... }
    static func stormy(confidence: Double, signals: [String],
                       nudge: NudgeType?, message: String?, practiceID: String?) -> StressAnalysisResponse { ... }
}
```

---

## Agent Specs — ScenarioRunner (PT.3)

```swift
actor ScenarioRunner {

    /// Execute a scenario against a fresh NudgeEngine.
    func execute(scenario: PlaytestScenario) async -> PlaytestResult {
        // 1. Create fresh NudgeEngine (isolated state per scenario)
        let engine = NudgeEngine()

        var stepResults: [PlaytestResult.StepResult] = []

        for step in scenario.steps {
            // 2. Simulate time passing
            if step.timeDelta > 0 {
                try? await Task.sleep(for: .milliseconds(10)) // symbolic delay
                // NudgeEngine uses Date() internally — for real time simulation
                // we'd need injectable clock. For hackathon: test logic, not timing.
            }

            // 3. Apply user action BEFORE evaluating nudge
            switch step.userAction {
            case .dismissImFine:
                await engine.recordDismissal(type: .imFine)
            case .dismissLater:
                await engine.recordDismissal(type: .later)
            case .completePractice:
                await engine.recordPracticeCompleted()
            case .startPractice, nil:
                break
            }

            // 4. Evaluate nudge decision
            let decision = await engine.shouldNudge(
                analysis: step.mockAnalysis,
                suppressionResult: .clear
            )

            // 5. Capture cooldown state
            let cooldown = await engine.cooldownSnapshot()

            stepResults.append(PlaytestResult.StepResult(
                id: step.id,
                nudgeDecision: decision,
                cooldownState: cooldown,
                timestamp: Date()
            ))
        }

        return PlaytestResult(
            scenarioID: scenario.id,
            stepResults: stepResults,
            totalDuration: scenario.steps.reduce(0) { $0 + $1.timeDelta }
        )
    }
}
```

**NudgeEngine changes needed:**

1. Add `cooldownSnapshot() -> PlaytestResult.CooldownSnapshot` method
2. Verify `recordDismissal(type:)` is publicly accessible
3. Verify `recordPracticeCompleted()` is publicly accessible

---

## Agent Specs — ResultEvaluator (PT.4)

```swift
struct ResultEvaluator: Sendable {
    let apiKey: String

    /// Evaluate a single scenario result using Opus 4.6 Extended Thinking
    func evaluate(
        scenario: PlaytestScenario,
        result: PlaytestResult
    ) async throws -> ScenarioEvaluation {
        // 1. Build evaluation prompt (see PRD_PLAYTEST.md section 6.1)
        let prompt = buildEvaluationPrompt(scenario: scenario, result: result)

        // 2. Call Opus 4.6 with Extended Thinking
        //    thinking.type = "enabled", budget_tokens = 4096
        //    model = "claude-opus-4-6-20250514"
        let response = try await callClaude(
            prompt: prompt,
            thinkingBudget: 4096,
            maxTokens: 2048
        )

        // 3. Parse JSON response into ScenarioEvaluation
        return parseEvaluation(response, scenarioID: scenario.id)
    }

    /// Generate final exploration report (max effort)
    func generateReport(rounds: [PlaytestRound]) async throws -> PlaytestReport {
        // Summary prompt (see PRD_PLAYTEST.md section 6.3)
        // thinking.budget_tokens = 10240 (max effort)
        // Returns PlaytestReport with discoveries, confidence trajectory, untested areas
    }

    // MARK: - Private

    private func buildEvaluationPrompt(scenario: PlaytestScenario, result: PlaytestResult) -> String {
        // Format scenario description, expected behavior, actual step results
        // Include hypothesis for AI-generated scenarios
        // See PRD_PLAYTEST.md section 6.1 for full template
    }

    private func callClaude(prompt: String, thinkingBudget: Int, maxTokens: Int) async throws -> (text: String, thinking: String?) {
        // Reuse ClaudeVisionClient's HTTP logic (same API, just text not image)
        // POST to https://api.anthropic.com/v1/messages
        // model: "claude-opus-4-6-20250514"
        // thinking: { type: "enabled", budget_tokens: thinkingBudget }
    }
}
```

**Implementation note:** Reuse `ClaudeVisionClient`'s HTTP/parsing logic. The evaluator uses the same API endpoint, just without images.

---

## Agent Specs — ScenarioGenerator (PT.5)

This is the **core innovation** — Opus 4.6 generates new test scenarios based on previous results.

```swift
struct ScenarioGenerator: Sendable {
    let apiKey: String

    /// Generate new scenarios based on all previous results.
    /// Returns 3-5 new PlaytestScenario with hypotheses.
    func generateNext(
        previousRounds: [PlaytestRound],
        roundNumber: Int
    ) async throws -> [PlaytestScenario] {
        // 1. Build generation prompt (see PRD_PLAYTEST.md section 6.2)
        let prompt = buildGenerationPrompt(previousRounds: previousRounds)

        // 2. Call Opus 4.6 with max effort Extended Thinking
        //    thinking.budget_tokens = 10240 (deep hypothesis generation)
        let response = try await callClaude(
            prompt: prompt,
            thinkingBudget: 10240,
            maxTokens: 4096
        )

        // 3. Parse JSON array of scenario definitions
        let generated = try parseGeneratedScenarios(response, roundNumber: roundNumber)

        // 4. Validate scenarios (valid steps, reasonable time deltas, etc.)
        return generated.filter { isValid($0) }
    }

    // MARK: - Prompt Building

    private func buildGenerationPrompt(previousRounds: [PlaytestRound]) -> String {
        // Include:
        // - APP RULES (cooldown constants, thresholds)
        // - All previous scenarios with evaluations
        // - Findings summary (passed, failed, low confidence)
        // - Instructions for generating 3-5 new scenarios
        // See PRD_PLAYTEST.md section 6.2 for full template
    }

    // MARK: - Parsing

    private func parseGeneratedScenarios(_ response: String, roundNumber: Int) throws -> [PlaytestScenario] {
        // Parse JSON response from Opus
        // Map each scenario JSON to PlaytestScenario struct
        // Set round = roundNumber
        // Extract hypothesis from each scenario
        // Generate assertions from expected_behavior where possible
    }

    // MARK: - Validation

    private func isValid(_ scenario: PlaytestScenario) -> Bool {
        // Must have at least 2 steps
        // Must have at least 1 expected behavior
        // Step IDs must be unique
        // Weather must be valid (clear/cloudy/stormy)
        // Confidence must be 0.0-1.0
        return !scenario.steps.isEmpty && !scenario.expectedBehavior.isEmpty
    }
}
```

**Key design:** The generator receives ALL previous results, so it can:

- Avoid duplicate scenarios
- Target areas where confidence was low
- Test combinations of behaviors from different scenarios
- Probe boundaries around failed or borderline tests

---

## Agent Specs — PlaytestService with Exploration Loop (PT.6)

```swift
@MainActor
@Observable
final class PlaytestService {
    // MARK: - Exploration Bounds
    private enum Bounds {
        static let maxRounds = 3
        static let maxScenariosPerRound = 5
        static let confidenceThreshold = 0.90
        static let timeoutSeconds: TimeInterval = 180  // 3 minutes
    }

    // MARK: - State
    var isRunning: Bool = false
    var currentRound: Int = 0
    var currentScenarioID: String?
    var progressMessage: String = ""
    var rounds: [PlaytestRound] = []
    var currentReport: PlaytestReport?
    var error: String?

    // MARK: - Dependencies
    private let runner: ScenarioRunner
    private let evaluator: ResultEvaluator
    private let generator: ScenarioGenerator
    private var runTask: Task<Void, Never>?

    // MARK: - Seed Catalog
    let seedScenarios: [PlaytestScenario] = PlaytestCatalog.allScenarios

    // MARK: - Computed

    var allScenarios: [PlaytestScenario] {
        rounds.flatMap(\.scenarios)
    }

    var allEvaluations: [String: ScenarioEvaluation] {
        var result: [String: ScenarioEvaluation] = [:]
        for round in rounds {
            for eval in round.evaluations {
                result[eval.scenarioID] = eval
            }
        }
        return result
    }

    var passedCount: Int { allEvaluations.values.filter(\.passed).count }
    var failedCount: Int { allEvaluations.values.filter { !$0.passed }.count }
    var totalCount: Int { allEvaluations.count }
    var seedCount: Int { seedScenarios.count }
    var generatedCount: Int { totalCount - seedCount }

    func evaluation(for scenarioID: String) -> ScenarioEvaluation? {
        allEvaluations[scenarioID]
    }

    func status(for scenarioID: String) -> ScenarioStatus {
        if currentScenarioID == scenarioID { return .running }
        if let eval = allEvaluations[scenarioID] { return eval.passed ? .passed : .failed }
        return .pending
    }

    enum ScenarioStatus {
        case pending, running, passed, failed
    }

    // MARK: - Exploration Loop

    func explore() {
        guard !isRunning else { return }
        let startTime = Date()
        runTask = Task {
            isRunning = true
            rounds = []
            currentReport = nil
            error = nil

            // ROUND 1: Seed scenarios
            currentRound = 1
            let round1 = await runRound(scenarios: seedScenarios, roundNumber: 1)
            rounds.append(round1)

            // Check stopping conditions
            var overallConfidence = averageConfidence(for: rounds)

            // EXPLORATION LOOP: Rounds 2+
            var roundNum = 2
            while roundNum <= Bounds.maxRounds
                    && overallConfidence < Bounds.confidenceThreshold
                    && Date().timeIntervalSince(startTime) < Bounds.timeoutSeconds {

                currentRound = roundNum
                progressMessage = "Round \(roundNum): Generating hypotheses..."

                // Generate new scenarios
                do {
                    let newScenarios = try await generator.generateNext(
                        previousRounds: rounds,
                        roundNumber: roundNum
                    )

                    if newScenarios.isEmpty {
                        progressMessage = "No new scenarios to test. Stopping."
                        break
                    }

                    // Run generated scenarios
                    let round = await runRound(scenarios: newScenarios, roundNumber: roundNum)
                    rounds.append(round)

                    overallConfidence = averageConfidence(for: rounds)
                } catch {
                    self.error = "Generation failed: \(error.localizedDescription)"
                    break
                }

                roundNum += 1
            }

            // FINAL: Generate exploration report
            progressMessage = "Generating exploration report..."
            do {
                currentReport = try await evaluator.generateReport(rounds: rounds)
            } catch {
                self.error = "Report failed: \(error.localizedDescription)"
            }

            isRunning = false
            currentScenarioID = nil
            progressMessage = ""
        }
    }

    func stop() {
        runTask?.cancel()
        runTask = nil
        isRunning = false
    }

    // MARK: - Private

    private func runRound(scenarios: [PlaytestScenario], roundNumber: Int) async -> PlaytestRound {
        var evaluations: [ScenarioEvaluation] = []

        for scenario in scenarios {
            currentScenarioID = scenario.id
            progressMessage = "Round \(roundNumber): Running \(scenario.name)..."

            let result = await runner.execute(scenario: scenario)

            progressMessage = "Round \(roundNumber): Evaluating \(scenario.name)..."
            do {
                let evaluation = try await evaluator.evaluate(scenario: scenario, result: result)
                evaluations.append(evaluation)
            } catch {
                evaluations.append(.error(scenarioID: scenario.id, message: error.localizedDescription))
            }
        }

        return PlaytestRound(
            id: roundNumber,
            scenarios: scenarios,
            evaluations: evaluations,
            isAIGenerated: roundNumber > 1
        )
    }

    private func averageConfidence(for rounds: [PlaytestRound]) -> Double {
        let allEvals = rounds.flatMap(\.evaluations)
        guard !allEvals.isEmpty else { return 0 }
        return allEvals.reduce(0) { $0 + $1.confidence } / Double(allEvals.count)
    }
}
```

---

## Agent Specs — UI (PT.7, PT.8)

### PlaytestView Layout

```
+--------------------------------------------------+
| ZONE A: Header (fixed, 60pt)                     |
|  [< Back]   testtube.2  PLAYTEST   [Explore]     |
+--------------------------------------------------+
| ZONE B: Rounds (scrollable)                       |
|                                                   |
|  Section: "ROUND 1 — Seed (8)"                   |
|  Each row: 44pt height                           |
|  [Status icon]  SC name         [confidence %]   |
|                                                   |
|  Section: "ROUND 2 — AI-Generated (4) 🤖"        |
|  Each row: same layout                            |
|  Shows hypothesis on subtitle line for generated  |
|                                                   |
|  Section: "ROUND 3 — AI-Generated (2) 🤖"        |
|  ...                                              |
+--------------------------------------------------+
| ZONE C: Progress (when running, 80pt)            |
|  "Round 2: Generating hypotheses..."              |
|  [████████████░░░░░░░] 11/14                      |
+--------------------------------------------------+
| ZONE D: Summary (after complete, 120pt)          |
|  "3 rounds · 14 scenarios · 91% confidence"       |
|  "8 seed + 6 AI-generated"                        |
|  Discoveries: 🔍 6 · 🐛 1 · ✅ 5                  |
|  AI summary (2-3 sentences)                       |
|  [Explore Again]                                   |
+--------------------------------------------------+
```

### Status Icons

- Passed: `checkmark.circle.fill` (jade green `#10B981`)
- Failed: `exclamationmark.triangle.fill` (gold `#D4AF37`)
- Running: `arrow.trianglehead.2.clockwise` (jade, rotation animation)
- Pending: `circle` (tertiary `rgba(224,244,238,0.45)`)

### Round Headers

- Round 1: "ROUND 1 — Seed (8)"
- Round 2+: "ROUND 2 — AI-Generated (4) 🤖" (robot emoji marks AI-created)

### ScenarioDetailView Layout

```
+--------------------------------------------------+
| [< Back]    SC-10: Boundary 31min       PASSED   |
| 🤖 AI-Generated · Round 2                         |
+--------------------------------------------------+
| HYPOTHESIS:                                       |
|  "SC-6 showed nudge interval issues at 10min.    |
|   Testing boundary at exactly 31min..."           |
+--------------------------------------------------+
| EXPECTED:                                         |
|  • Nudge allowed after 31 minutes                |
| ACTUAL:                                           |
|  • Nudge correctly shown at 31 minutes ✅         |
+--------------------------------------------------+
| AI ANALYSIS:                                      |
|  brain.head.profile  Effort: ●●○ HIGH            |
|  "The 31-minute boundary works correctly..."      |
|                                                   |
|  Confidence: 85%                                  |
|  Mismatches: (none)                               |
|  Suggestions: [expandable list]                  |
+--------------------------------------------------+
| [View Full Thinking]         [Rerun Scenario]     |
+--------------------------------------------------+
```

**For seed scenarios:** Hypothesis section is hidden (no hypothesis).
**For AI-generated:** Hypothesis section shows why this test was created.

### Color Scheme (Heritage Jade Dark)

- Background: `#0A1F1A`
- Passed: `#10B981` (jade green)
- Failed: `#D4AF37` (gold)
- Running: `#10B981` with rotation animation
- Pending: `rgba(224,244,238,0.45)` (tertiary)
- Confidence >= 80%: jade, 60-79%: blue-gray `#8BA4B0`, < 60%: gold
- AI card: `rgba(199,232,222,0.08)` surface
- Round header: `rgba(224,244,238,0.60)` secondary text
- Hypothesis text: italic, `rgba(224,244,238,0.72)` secondary

### Animations

- Scenario status change: crossfade 0.3s
- Running indicator: continuous rotation, 1s per cycle
- Progress bar: smooth width animation 0.3s
- New round appearing: fade in + slide up 8pt, 0.4s
- Summary appear: fade in + slide up 12pt, 0.5s

---

## Agent Specs — Integration (PT.9)

### AppState Changes

```swift
// Add to Screen enum:
case playtest

// Add service reference:
var playtestService: PlaytestService?

func configurePlaytest(_ service: PlaytestService) {
    self.playtestService = service
}

func showPlaytest() {
    currentScreen = .playtest
}
```

### MainView Changes

```swift
case .playtest:
    if let service = appState.playtestService {
        PlaytestView(service: service, onBack: { appState.currentScreen = .settings })
    }
```

### SettingsView Changes

```swift
private var playtestSection: some View {
    VStack(alignment: .leading, spacing: 14) {
        sectionHeader(title: "PLAYTEST", icon: "testtube.2")

        Text("AI exploration loop. Opus 4.6 tests the app, finds blind spots, and invents new tests.")
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.45))

        Button("Run Exploration") {
            appState.showPlaytest()
        }
        .buttonStyle(/* jade button style */)
    }
}
```

### RespiroDesktopApp.swift

```swift
let playtestService = PlaytestService(apiKey: apiKey)
appState.configurePlaytest(playtestService)
```

---

## Sprint Plan

| Phase              | Tasks                     | Parallel?      | Est  |
| ------------------ | ------------------------- | -------------- | ---- |
| 1. Models          | PT.1                      | —              | 1.5h |
| 2. Core (parallel) | PT.2 + PT.3 + PT.4 + PT.5 | Yes (4 agents) | 2h   |
| 3. Service         | PT.6                      | —              | 2h   |
| 4. UI (parallel)   | PT.7 + PT.8               | Yes (2 views)  | 2.5h |
| 5. Integration     | PT.9                      | —              | 1h   |

**Critical path:** PT.1 → PT.3/PT.5 → PT.6 → PT.9
**Total: ~9-11h wall time (with parallel execution)**

---

## Key Decisions

1. **Exploration loop with bounds.** Max 3 rounds, max 5 scenarios/round, 90% confidence stop, 3-min timeout.
2. **Opus generates scenarios as JSON.** Parsed into same PlaytestScenario struct. First-class citizens.
3. **Hypothesis-driven.** Every AI-generated scenario has a hypothesis explaining why it might find a bug.
4. **Round grouping in UI.** Clear visual separation between seed and AI-generated scenarios.
5. **Tests against real NudgeEngine.** Real logic, real bugs. Fresh instance per scenario.
6. **Evaluation + Generation = two Opus roles.** Evaluator reasons about correctness, Generator reasons about what to test next.

---

## What NOT to Build

- Custom scenario editor (add scenarios in code or let AI generate)
- Scenario recording from real sessions
- Screenshot-based visual testing
- CLI mode (post-hackathon)
- Persistent exploration history across sessions
- Auto-fix (Opus suggests code patches)
