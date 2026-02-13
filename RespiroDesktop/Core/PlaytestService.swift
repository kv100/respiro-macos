import Foundation
import OSLog

@MainActor
@Observable
final class PlaytestService {
    private let logger = Logger(subsystem: "com.respiro.desktop", category: "Playtest")
    // MARK: - Exploration Bounds
    private enum Bounds {
        static let maxRounds = 3
        static let maxScenariosPerRound = 10
        static let confidenceThreshold = 0.90
        static let timeoutSeconds: TimeInterval = 1200  // 20 minutes (for full 3-round exploration with 10 scenarios/round)
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

    init(mode: ClaudeVisionClient.Mode) {
        self.runner = ScenarioRunner()
        self.evaluator = ResultEvaluator(mode: mode)
        self.generator = ScenarioGenerator(mode: mode)
    }

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
    var generatedCount: Int { max(0, allScenarios.count - seedCount) }

    var failedScenarios: [PlaytestScenario] {
        let failedIDs = Set(allEvaluations.filter { !$0.value.passed }.map(\.key))
        return allScenarios.filter { failedIDs.contains($0.id) }
    }

    // MARK: - Regression Suite (Persisted)

    var hasRegressionSuite: Bool {
        FileManager.default.fileExists(atPath: regressionFileURL.path)
    }

    var regressionCount: Int {
        loadRegressionBugs().count
    }

    private var regressionFileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let reportsDir = documents.appendingPathComponent("Respiro_Playtest_Reports", isDirectory: true)
        try? FileManager.default.createDirectory(at: reportsDir, withIntermediateDirectories: true)
        return reportsDir.appendingPathComponent("regression_suite.json")
    }

    private func loadRegressionBugs() -> [RegressionBug] {
        guard let data = try? Data(contentsOf: regressionFileURL) else {
            print("[Playtest] No regression file found")
            return []
        }
        do {
            let bugs = try JSONDecoder().decode([RegressionBug].self, from: data)
            print("[Playtest] Loaded \(bugs.count) regression bugs")
            return bugs
        } catch {
            print("[Playtest] Failed to decode regression bugs: \(error)")
            return []
        }
    }

    private func saveRegressionSuite() {
        // Collect bugs from failed evaluations
        var bugs: [RegressionBug] = []
        for round in rounds {
            for (index, eval) in round.evaluations.enumerated() {
                guard !eval.passed, let scenario = round.scenarios[safe: index] else { continue }
                bugs.append(RegressionBug(
                    scenarioID: scenario.id,
                    scenarioName: scenario.name,
                    description: scenario.description,
                    hypothesis: scenario.hypothesis,
                    mismatches: eval.mismatches,
                    expectedBehavior: scenario.expectedBehavior,
                    round: scenario.round
                ))
            }
        }

        guard !bugs.isEmpty else {
            try? FileManager.default.removeItem(at: regressionFileURL)
            print("[Playtest] No failures -- regression suite cleared")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(bugs)
            try data.write(to: regressionFileURL)
            print("[Playtest] Saved \(bugs.count) bugs to regression suite")
        } catch {
            print("[Playtest] Failed to save regression suite: \(error)")
        }
    }

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
            let round1 = await runRoundParallel(scenarios: seedScenarios, roundNumber: 1)
            rounds.append(round1)

            let round1Confidence = averageConfidence(for: rounds)
            print("[Playtest] Round 1 completed. Confidence: \(round1Confidence)")
            print("[Playtest] Starting full exploration (always run 3 rounds)...")

            // EXPLORATION LOOP: Rounds 2+ (always run all rounds to see full AI exploration)
            var roundNum = 2
            let elapsed = Date().timeIntervalSince(startTime)
            print("[Playtest] While loop check: roundNum=\(roundNum), maxRounds=\(Bounds.maxRounds), elapsed=\(elapsed)s, timeout=\(Bounds.timeoutSeconds)s")
            while roundNum <= Bounds.maxRounds
                    && Date().timeIntervalSince(startTime) < Bounds.timeoutSeconds {

                guard !Task.isCancelled else {
                    print("[Playtest] Task cancelled, breaking loop")
                    break
                }

                currentRound = roundNum
                print("[Playtest] Starting Round \(roundNum). Generating hypotheses...")
                progressMessage = "Round \(roundNum): Generating hypotheses..."

                do {
                    let newScenarios = try await generator.generateNext(
                        previousRounds: rounds,
                        roundNumber: roundNum
                    )
                    print("[Playtest] Generated \(newScenarios.count) new scenarios")

                    if newScenarios.isEmpty {
                        progressMessage = "No new scenarios to test. Stopping."
                        break
                    }

                    let round = await runRoundParallel(scenarios: newScenarios, roundNumber: roundNum)
                    rounds.append(round)
                } catch {
                    print("[Playtest] Generation failed: \(error)")
                    self.error = "Generation failed: \(error.localizedDescription)"
                    break
                }

                roundNum += 1
            }

            let finalConfidence = averageConfidence(for: rounds)
            print("[Playtest] Exploration stopped. Rounds: \(rounds.count), Final confidence: \(finalConfidence)")

            // FINAL: Generate exploration report
            if !Task.isCancelled {
                progressMessage = "Generating exploration report..."
                do {
                    currentReport = try await evaluator.generateReport(rounds: rounds)
                } catch {
                    self.error = "Report failed: \(error.localizedDescription)"
                }

                saveResults()
                saveRegressionSuite()
            }

            isRunning = false
            currentScenarioID = nil
            progressMessage = ""
        }
    }

    func runFailedOnly() {
        let bugs = loadRegressionBugs()
        guard !bugs.isEmpty, !isRunning else { return }

        runTask = Task {
            isRunning = true
            rounds = []
            currentReport = nil
            error = nil
            currentRound = 1

            // Phase 1: AI generates fresh regression scenarios from bug descriptions
            progressMessage = "Generating \(bugs.count) regression scenarios..."

            let scenarios: [PlaytestScenario]
            do {
                scenarios = try await generator.generateRegressionScenarios(bugs: bugs)
                print("[Regression] Generated \(scenarios.count) regression scenarios")
            } catch {
                self.error = "Regression generation failed: \(error.localizedDescription)"
                isRunning = false
                return
            }

            guard !scenarios.isEmpty else {
                self.error = "No regression scenarios generated"
                isRunning = false
                return
            }

            // Phase 2: Run scenarios with parallel evaluation
            progressMessage = "Running \(scenarios.count) regression scenarios..."
            let round = await runRoundParallel(scenarios: scenarios, roundNumber: 1)
            rounds.append(round)

            // Phase 3: Report
            if !Task.isCancelled {
                let passedCount = round.evaluations.filter(\.passed).count
                let failedCount = round.evaluations.count - passedCount

                if failedCount == 0 {
                    currentReport = PlaytestReport(
                        rounds: rounds,
                        overallPassed: true,
                        overallConfidence: 1.0,
                        summary: "All \(passedCount) regression bugs verified as FIXED.",
                        discoveries: [],
                        criticalIssues: [],
                        strengths: ["All \(passedCount) previously failing scenarios now pass"],
                        untestedAreas: [],
                        confidenceTrajectory: [],
                        thinkingText: nil,
                        completedAt: Date()
                    )
                } else {
                    progressMessage = "Generating regression report..."
                    do {
                        currentReport = try await evaluator.generateReport(rounds: rounds)
                    } catch {
                        self.error = "Report failed: \(error.localizedDescription)"
                    }
                }

                saveResults()
                saveRegressionSuite()  // Update with remaining failures
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
        currentScenarioID = nil
        progressMessage = ""
    }

    // MARK: - Parallel Evaluation

    /// Run scenarios sequentially (fast, in-memory execution) then evaluate in parallel with a concurrency limit.
    /// This is faster than runRound for AI-generated scenarios because evaluations (API calls) overlap.
    private func runRoundParallel(scenarios: [PlaytestScenario], roundNumber: Int, maxConcurrency: Int = 3) async -> PlaytestRound {
        // Phase 1: Execute all scenarios sequentially (fast, no API)
        var executionResults: [(PlaytestScenario, PlaytestResult)] = []
        for (index, scenario) in scenarios.enumerated() {
            guard !Task.isCancelled else { break }
            currentScenarioID = scenario.id
            progressMessage = "Round \(roundNumber): Executing \(scenario.name) (\(index + 1)/\(scenarios.count))"

            let result = await runner.execute(scenario: scenario) { [weak self] stepNum, totalSteps in
                guard let self else { return }
                await MainActor.run {
                    self.progressMessage = "Round \(roundNumber): \(scenario.name) — Step \(stepNum)/\(totalSteps)"
                }
            }
            executionResults.append((scenario, result))
        }

        // Phase 2: Evaluate in parallel with concurrency limit
        progressMessage = "Round \(roundNumber): Evaluating \(executionResults.count) scenarios..."

        // Capture evaluator (Sendable struct) for use in task group
        let evalRef = evaluator
        let totalCount = executionResults.count

        // Create indexed work items for ordered results
        struct IndexedEvaluation: Sendable {
            let index: Int
            let evaluation: ScenarioEvaluation
        }

        let indexedResults: [IndexedEvaluation] = await withTaskGroup(of: IndexedEvaluation.self) { group in
            var results: [IndexedEvaluation] = []
            var nextIndex = 0

            // Seed initial batch up to maxConcurrency
            while nextIndex < min(maxConcurrency, executionResults.count) {
                let idx = nextIndex
                let (scenario, result) = executionResults[idx]
                group.addTask {
                    do {
                        let eval = try await evalRef.evaluate(scenario: scenario, result: result)
                        return IndexedEvaluation(index: idx, evaluation: eval)
                    } catch {
                        return IndexedEvaluation(index: idx, evaluation: .error(scenarioID: scenario.id, message: error.localizedDescription))
                    }
                }
                nextIndex += 1
            }

            // Process results and add new tasks as slots free up
            for await indexed in group {
                results.append(indexed)

                // Update progress on main actor
                let completedCount = results.count
                await MainActor.run {
                    self.progressMessage = "Round \(roundNumber): Evaluated \(completedCount)/\(totalCount)..."
                }

                if nextIndex < executionResults.count {
                    let idx = nextIndex
                    let (scenario, result) = executionResults[idx]
                    group.addTask {
                        do {
                            let eval = try await evalRef.evaluate(scenario: scenario, result: result)
                            return IndexedEvaluation(index: idx, evaluation: eval)
                        } catch {
                            return IndexedEvaluation(index: idx, evaluation: .error(scenarioID: scenario.id, message: error.localizedDescription))
                        }
                    }
                    nextIndex += 1
                }
            }

            return results
        }

        // Sort evaluations back to scenario order
        let orderedEvals = indexedResults
            .sorted { $0.index < $1.index }
            .map(\.evaluation)

        // If some scenarios were skipped (cancellation), fill with errors
        let finalEvals: [ScenarioEvaluation] = scenarios.enumerated().map { index, scenario in
            if index < orderedEvals.count {
                return orderedEvals[index]
            } else {
                return .error(scenarioID: scenario.id, message: "Skipped due to cancellation")
            }
        }

        return PlaytestRound(
            id: roundNumber,
            scenarios: scenarios,
            evaluations: finalEvals,
            isAIGenerated: roundNumber > 1
        )
    }

    // MARK: - Private

    private func runRound(scenarios: [PlaytestScenario], roundNumber: Int) async -> PlaytestRound {
        var evaluations: [ScenarioEvaluation] = []

        for (scenarioIndex, scenario) in scenarios.enumerated() {
            guard !Task.isCancelled else { break }
            currentScenarioID = scenario.id
            let scenarioNum = scenarioIndex + 1
            let totalScenarios = scenarios.count

            logger.info("📋 [Round \(roundNumber)] Scenario \(scenarioNum)/\(totalScenarios): \(scenario.id) \"\(scenario.name)\"")
            progressMessage = "Round \(roundNumber): \(scenario.name) (scenario \(scenarioNum)/\(totalScenarios))"

            // Execute with step-by-step progress
            let result = await runner.execute(scenario: scenario) { [weak self] stepNum, totalSteps in
                guard let self = self else { return }
                await MainActor.run {
                    self.progressMessage = "Round \(roundNumber): \(scenario.name) — Step \(stepNum)/\(totalSteps)"
                }
            }

            logger.info("✅ [Round \(roundNumber)] Scenario \(scenario.id) executed (\(result.stepResults.count) steps)")

            progressMessage = "Round \(roundNumber): Evaluating \(scenario.name)..."
            logger.debug("🔍 [Round \(roundNumber)] Evaluating \(scenario.id)...")

            do {
                let evaluation = try await evaluator.evaluate(scenario: scenario, result: result)
                logger.info("📊 [Round \(roundNumber)] Evaluation: \(scenario.id) - passed: \(evaluation.passed), confidence: \(String(format: "%.1f%%", evaluation.confidence * 100))")
                evaluations.append(evaluation)
            } catch {
                logger.error("❌ [Round \(roundNumber)] Evaluation FAILED: \(scenario.id) - \(error.localizedDescription)")
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

    private func saveResults() {
        guard !rounds.isEmpty else { return }

        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[Playtest] Failed to find Documents directory")
            return
        }

        let reportsDir = documents.appendingPathComponent("Respiro_Playtest_Reports", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: reportsDir, withIntermediateDirectories: true)

        // Create filename with readable timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = "playtest_\(timestamp).json"
        let fileURL = reportsDir.appendingPathComponent(filename)

        // Build JSON structure
        var json: [String: Any] = [
            "timestamp": timestamp,
            "rounds_count": rounds.count,
            "total_scenarios": allScenarios.count,
            "seed_count": seedCount,
            "generated_count": generatedCount,
            "passed_count": passedCount,
            "failed_count": failedCount,
            "rounds": []
        ]

        var roundsJSON: [[String: Any]] = []
        for round in rounds {
            var roundJSON: [String: Any] = [
                "id": round.id,
                "is_ai_generated": round.isAIGenerated,
                "scenarios": []
            ]

            var scenariosJSON: [[String: Any]] = []
            for scenario in round.scenarios {
                let eval = evaluation(for: scenario.id)
                var scenarioJSON: [String: Any] = [
                    "id": scenario.id,
                    "name": scenario.name,
                    "description": scenario.description,
                    "round": scenario.round,
                    "passed": eval?.passed ?? false,
                    "confidence": eval?.confidence ?? 0,
                    "reasoning": eval?.reasoning ?? "",
                    "mismatches": eval?.mismatches ?? [],
                    "suggestions": eval?.suggestions ?? []
                ]
                if let hypothesis = scenario.hypothesis {
                    scenarioJSON["hypothesis"] = hypothesis
                }
                scenariosJSON.append(scenarioJSON)
            }
            roundJSON["scenarios"] = scenariosJSON
            roundsJSON.append(roundJSON)
        }
        json["rounds"] = roundsJSON

        if let report = currentReport {
            json["report"] = [
                "overall_passed": report.overallPassed,
                "overall_confidence": report.overallConfidence,
                "summary": report.summary,
                "discoveries": report.discoveries,
                "critical_issues": report.criticalIssues,
                "strengths": report.strengths,
                "untested_areas": report.untestedAreas
            ]
        }

        // Write to file
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
            print("[Playtest] Results saved to: \(fileURL.path)")
        } catch {
            print("[Playtest] Failed to save results: \(error)")
        }
    }
}
