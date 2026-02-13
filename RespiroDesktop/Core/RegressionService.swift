import Foundation
import SwiftData

// MARK: - Regression Service

/// Actor managing regression test suite for failed scenarios
actor RegressionService {
    // MARK: - Dependencies
    private let modelContainer: ModelContainer

    // MARK: - Config
    private enum Config {
        static let passesRequiredToFix = 2  // Consecutive passes needed to mark as fixed
    }

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Public API

    /// Add a failed scenario to regression suite
    func addFailedScenario(_ scenario: PlaytestScenario, _ eval: ScenarioEvaluation) async {
        let context = ModelContext(modelContainer)

        // Check if already tracked
        let scenarioID = scenario.id
        let descriptor = FetchDescriptor<RegressionEntry>(
            predicate: #Predicate { $0.scenarioID == scenarioID }
        )

        do {
            let existing = try context.fetch(descriptor)

            if existing.isEmpty {
                // New failure - add to regression suite
                let entry = RegressionEntry(
                    scenarioID: scenario.id,
                    scenarioName: scenario.name,
                    originalRound: scenario.round,
                    firstFailedAt: Date(),
                    lastTestedAt: Date(),
                    status: "stillFailing",
                    consecutivePasses: 0
                )
                context.insert(entry)
                try context.save()
                print("[Regression] Added new failure: \(scenario.name)")
            } else {
                // Already tracked - check for regression
                guard let entry = existing.first else { return }
                entry.lastTestedAt = Date()

                // If was previously fixed, this is a regression
                if entry.status == "fixed" {
                    entry.updateStatus(to: .regression)
                    entry.consecutivePasses = 0
                    try context.save()
                    print("[Regression] REGRESSION detected: \(scenario.name) failed again!")
                } else {
                    // Still failing - just update timestamp
                    try context.save()
                    print("[Regression] Still failing: \(scenario.name)")
                }
            }
        } catch {
            print("[Regression] Error tracking failure: \(error)")
        }
    }

    /// Run full regression suite against current code
    func runRegressionSuite(
        runner: ScenarioRunner,
        evaluator: ResultEvaluator
    ) async -> [ScenarioEvaluation] {
        print("[Regression] Starting regression suite...")

        // Fetch all tracked failures
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RegressionEntry>(
            predicate: #Predicate { $0.status != "fixed" }
        )

        var entries: [RegressionEntry]
        do {
            entries = try context.fetch(descriptor)
            print("[Regression] Found \(entries.count) scenarios to retest")
        } catch {
            print("[Regression] Error fetching entries: \(error)")
            return []
        }

        guard !entries.isEmpty else {
            print("[Regression] No failures to retest")
            return []
        }

        // Load scenarios from PlaytestCatalog
        let allScenarios = PlaytestCatalog.allScenarios
        var evaluations: [ScenarioEvaluation] = []

        for entry in entries {
            guard let scenario = allScenarios.first(where: { $0.id == entry.scenarioID }) else {
                print("[Regression] Scenario \(entry.scenarioID) not found in catalog")
                continue
            }

            print("[Regression] Testing: \(scenario.name)...")

            // Run scenario
            let result = await runner.execute(scenario: scenario)

            // Evaluate
            do {
                let eval = try await evaluator.evaluate(scenario: scenario, result: result)
                evaluations.append(eval)

                // Update status based on result
                await updateStatus(scenarioID: entry.scenarioID, passed: eval.passed)
            } catch {
                print("[Regression] Evaluation failed for \(scenario.name): \(error)")
                let errorEval = ScenarioEvaluation.error(
                    scenarioID: scenario.id,
                    message: error.localizedDescription
                )
                evaluations.append(errorEval)
            }
        }

        print("[Regression] Regression suite completed. \(evaluations.count) scenarios tested")
        return evaluations
    }

    /// Update status after test run
    func updateStatus(scenarioID: String, passed: Bool) async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RegressionEntry>(
            predicate: #Predicate { $0.scenarioID == scenarioID }
        )

        do {
            let entries = try context.fetch(descriptor)
            guard let entry = entries.first else { return }

            entry.lastTestedAt = Date()

            if passed {
                entry.consecutivePasses += 1

                // Mark as fixed if enough consecutive passes
                if entry.consecutivePasses >= Config.passesRequiredToFix {
                    entry.updateStatus(to: .fixed)
                    entry.fixedAt = Date()
                    print("[Regression] ✅ FIXED: \(entry.scenarioName) (passed \(entry.consecutivePasses) times)")
                } else {
                    print("[Regression] ⚠️ Pass #\(entry.consecutivePasses)/\(Config.passesRequiredToFix): \(entry.scenarioName)")
                }
            } else {
                // Failed again - reset counter
                entry.consecutivePasses = 0

                if entry.status == "fixed" {
                    // Was fixed, now failing = regression
                    entry.updateStatus(to: .regression)
                    print("[Regression] ❌ REGRESSION: \(entry.scenarioName)")
                } else {
                    // Still failing
                    print("[Regression] ❌ Still failing: \(entry.scenarioName)")
                }
            }

            try context.save()
        } catch {
            print("[Regression] Error updating status: \(error)")
        }
    }

    /// Get summary of regression suite status
    func summary() async -> (stillFailing: Int, fixed: Int, regression: Int, total: Int) {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RegressionEntry>()

        do {
            let entries = try context.fetch(descriptor)

            let stillFailing = entries.filter { $0.status == "stillFailing" }.count
            let fixed = entries.filter { $0.status == "fixed" }.count
            let regression = entries.filter { $0.status == "regression" }.count

            print("[Regression] Summary: \(stillFailing) failing, \(fixed) fixed, \(regression) regressions (total: \(entries.count))")
            return (stillFailing: stillFailing, fixed: fixed, regression: regression, total: entries.count)
        } catch {
            print("[Regression] Error fetching summary: \(error)")
            return (0, 0, 0, 0)
        }
    }

    /// Get all regression entries (for UI display)
    func allEntries() async -> [RegressionEntry] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RegressionEntry>(
            sortBy: [SortDescriptor(\.lastTestedAt, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("[Regression] Error fetching entries: \(error)")
            return []
        }
    }

    /// Clear all fixed scenarios from regression suite
    func clearFixed() async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<RegressionEntry>(
            predicate: #Predicate { $0.status == "fixed" }
        )

        do {
            let fixedEntries = try context.fetch(descriptor)
            for entry in fixedEntries {
                context.delete(entry)
            }
            try context.save()
            print("[Regression] Cleared \(fixedEntries.count) fixed entries")
        } catch {
            print("[Regression] Error clearing fixed entries: \(error)")
        }
    }
}
