import Foundation

@MainActor
@Observable
final class PlaytestService {
    // MARK: - Exploration Bounds
    private enum Bounds {
        static let maxRounds = 3
        static let maxScenariosPerRound = 5
        static let confidenceThreshold = 0.90
        static let timeoutSeconds: TimeInterval = 900  // 15 minutes (for full 3-round exploration with AI generation)
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

                    let round = await runRound(scenarios: newScenarios, roundNumber: roundNum)
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

    // MARK: - Private

    private func runRound(scenarios: [PlaytestScenario], roundNumber: Int) async -> PlaytestRound {
        var evaluations: [ScenarioEvaluation] = []

        for scenario in scenarios {
            guard !Task.isCancelled else { break }
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
