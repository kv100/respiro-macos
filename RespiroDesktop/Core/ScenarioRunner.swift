import Foundation

actor ScenarioRunner {

    func execute(scenario: PlaytestScenario) async -> PlaytestResult {
        let engine = NudgeEngine()
        var stepResults: [PlaytestResult.StepResult] = []

        for step in scenario.steps {
            // 1. Advance simulated time
            if step.timeDelta > 0 {
                await engine.advanceTime(by: step.timeDelta)
            }

            // 2. Evaluate nudge decision FIRST
            let decision = await engine.shouldNudge(for: step.mockAnalysis)

            // 3. If nudge approved, record it (updates cooldown tracking)
            if decision.shouldShow, let nudgeType = decision.nudgeType {
                await engine.recordNudgeShown(type: nudgeType)
            }

            // 4. Apply user action AFTER evaluation (affects subsequent steps)
            switch step.userAction {
            case .dismissImFine, .dismissLater:
                await engine.recordDismissal()
            case .completePractice:
                await engine.recordPracticeCompleted()
            case .startPractice, nil:
                break
            }

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
