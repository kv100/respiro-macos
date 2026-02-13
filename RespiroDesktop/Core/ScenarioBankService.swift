import Foundation
import SwiftData

/// Actor for managing scenario persistence and duplicate detection
actor ScenarioBankService {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Public API

    /// Save a scenario to the bank
    func saveScenario(_ scenario: PlaytestScenario, round: Int) async {
        let context = ModelContext(modelContainer)

        // Check if already saved
        let scenarioID = scenario.id
        let descriptor = FetchDescriptor<ScenarioBankEntry>(
            predicate: #Predicate { $0.id == scenarioID }
        )

        if let existing = try? context.fetch(descriptor).first {
            print("[ScenarioBank] Scenario \(scenario.id) already saved, skipping")
            return
        }

        let entry = ScenarioBankEntry(
            id: scenario.id,
            name: scenario.name,
            description: scenario.description,
            hypothesis: scenario.hypothesis,
            generatedAt: Date(),
            usedInRound: round
        )

        context.insert(entry)

        do {
            try context.save()
            print("[ScenarioBank] Saved scenario: \(scenario.name) (round \(round))")
        } catch {
            print("[ScenarioBank] Failed to save scenario \(scenario.id): \(error)")
        }
    }

    /// Check if a new scenario is a duplicate (fuzzy match on name/description)
    func isDuplicate(_ newScenario: PlaytestScenario) async -> Bool {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ScenarioBankEntry>()

        guard let allEntries = try? context.fetch(descriptor) else {
            return false
        }

        // Normalize strings for comparison
        let newName = normalize(newScenario.name)
        let newDesc = normalize(newScenario.description)

        for entry in allEntries {
            let entryName = normalize(entry.name)
            let entryDesc = normalize(entry.scenarioDescription)

            // Fuzzy match: 80%+ similarity on name OR description
            if similarity(newName, entryName) > 0.8 {
                print("[ScenarioBank] Duplicate detected (name match): \(newScenario.name) ≈ \(entry.name)")
                return true
            }

            if similarity(newDesc, entryDesc) > 0.8 {
                print("[ScenarioBank] Duplicate detected (description match): \(newScenario.name)")
                return true
            }
        }

        return false
    }

    /// Get all saved scenarios (newest first)
    func allHistory() async -> [ScenarioBankEntry] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ScenarioBankEntry>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )

        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Private Helpers

    /// Normalize string for comparison (lowercase, trim, collapse whitespace)
    private func normalize(_ string: String) -> String {
        string
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    /// Calculate similarity between two strings (0.0 - 1.0)
    /// Uses Levenshtein distance normalized by string length
    private func similarity(_ s1: String, _ s2: String) -> Double {
        let distance = levenshteinDistance(s1, s2)
        let maxLen = Double(max(s1.count, s2.count))
        guard maxLen > 0 else { return 1.0 }
        return 1.0 - (Double(distance) / maxLen)
    }

    /// Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        guard m > 0 else { return n }
        guard n > 0 else { return m }

        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }
}
