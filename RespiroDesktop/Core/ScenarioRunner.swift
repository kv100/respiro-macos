import Foundation
import OSLog

actor ScenarioRunner {
    private let logger = Logger(subsystem: "com.respiro.desktop", category: "Playtest")

    // MARK: - Execution

    func execute(
        scenario: PlaytestScenario,
        onStepProgress: (@Sendable (Int, Int) async -> Void)? = nil
    ) async -> PlaytestResult {
        let engine = NudgeEngine()
        var stepResults: [PlaytestResult.StepResult] = []
        let totalSteps = scenario.steps.count

        logger.info("🧪 [Scenario] Starting: \(scenario.id) \"\(scenario.name)\" (\(totalSteps) steps)")

        for (stepIndex, step) in scenario.steps.enumerated() {
            let stepNum = stepIndex + 1
            logger.debug("  → Step \(stepNum)/\(totalSteps): \(step.id) - \(step.description)")

            // Notify progress
            await onStepProgress?(stepNum, totalSteps)
            // 1. Advance simulated time
            if step.timeDelta > 0 {
                await engine.advanceTime(by: step.timeDelta)
            }

            // 2. Enhance mock analysis with behavioral context
            var enhancedAnalysis = step.mockAnalysis
            if let metrics = step.behaviorMetrics, let deviation = step.baselineDeviation {
                // Add behavioral reasoning to thinkingText
                let behavioralReasoning = buildBehavioralReasoning(
                    metrics: metrics,
                    deviation: deviation,
                    systemContext: step.systemContext
                )

                // Combine with existing thinking text if present
                if let existing = enhancedAnalysis.thinkingText {
                    enhancedAnalysis.thinkingText = existing + "\n\n" + behavioralReasoning
                } else {
                    enhancedAnalysis.thinkingText = behavioralReasoning
                }
            }

            // 3. Build behavioral context and evaluate nudge decision
            var behavioralContext: BehavioralContext? = nil
            if let metrics = step.behaviorMetrics, let deviation = step.baselineDeviation {
                behavioralContext = BehavioralContext(
                    metrics: metrics,
                    baselineDeviation: deviation,
                    systemContext: step.systemContext
                )
            }
            let decision = await engine.shouldNudge(for: enhancedAnalysis, behavioral: behavioralContext)

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
                timestamp: Date(),
                behaviorMetrics: step.behaviorMetrics,
                baselineDeviation: step.baselineDeviation
            ))
        }

        return PlaytestResult(
            scenarioID: scenario.id,
            stepResults: stepResults,
            totalDuration: scenario.steps.reduce(0) { $0 + $1.timeDelta }
        )
    }

    // MARK: - Behavioral Context

    /// Build behavioral reasoning text from metrics
    private func buildBehavioralReasoning(
        metrics: BehaviorMetrics,
        deviation: Double,
        systemContext: SystemContext?
    ) -> String {
        var reasoning = "## Behavioral Context\n"

        // Context switching analysis
        let switchRate = metrics.contextSwitchesPerMinute
        if switchRate > 10 {
            reasoning += "- High context switching (\(String(format: "%.1f", switchRate))/min) suggests task fragmentation\n"
        } else if switchRate > 5 {
            reasoning += "- Moderate context switching (\(String(format: "%.1f", switchRate))/min)\n"
        } else {
            reasoning += "- Low context switching (\(String(format: "%.1f", switchRate))/min) - focused work\n"
        }

        // Session duration
        let hours = metrics.sessionDuration / 3600
        if hours > 3 {
            reasoning += "- Extended session (\(String(format: "%.1f", hours))h) without break\n"
        }

        // Application focus
        if let topApp = metrics.applicationFocus.max(by: { $0.value < $1.value }) {
            let percentage = topApp.value * 100
            reasoning += "- Primary focus: \(topApp.key) (\(String(format: "%.0f", percentage))%%)\n"
        }

        // Notifications
        if metrics.notificationAccumulation > 5 {
            reasoning += "- \(metrics.notificationAccumulation) pending notifications may indicate avoidance\n"
        }

        // Baseline deviation
        let deviationPercent = deviation * 100
        reasoning += "\n**Baseline deviation:** \(String(format: "%+.0f", deviationPercent))%%"
        if abs(deviation) > 0.3 {
            reasoning += " (significant)"
        } else if abs(deviation) > 0.15 {
            reasoning += " (moderate)"
        } else {
            reasoning += " (normal)"
        }

        // System context
        if let context = systemContext {
            reasoning += "\n\n## System State\n"
            reasoning += "- Active: \(context.activeApp)\n"
            if let title = context.activeWindowTitle {
                reasoning += "- Window: \(title)\n"
            }
            reasoning += "- Open windows: \(context.openWindowCount)\n"
            if context.isOnVideoCall {
                reasoning += "- Video call active\n"
            }
        }

        return reasoning
    }
}
