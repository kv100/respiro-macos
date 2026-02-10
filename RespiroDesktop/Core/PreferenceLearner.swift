import Foundation
import SwiftData

@MainActor
final class PreferenceLearner {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Build a ranked list of preferred practice IDs based on user history.
    func rankedPracticeIDs() -> [String] {
        let sessions = fetchCompletedSessions()
        guard !sessions.isEmpty else { return [] }

        var scores: [String: Double] = [:]

        for session in sessions {
            let practiceID = session.practiceID
            // Completion counts
            scores[practiceID, default: 0] += 1.0

            // Weather improvement bonus
            if let before = InnerWeather(rawValue: session.weatherBefore),
               let afterStr = session.weatherAfter,
               let after = InnerWeather(rawValue: afterStr) {
                let delta = weatherScore(before) - weatherScore(after)
                if delta > 0 {
                    scores[practiceID, default: 0] += delta * 2.0
                }
            }

            // "What Helped" positive feedback bonus
            if let helped = session.whatHelped, !helped.isEmpty {
                scores[practiceID, default: 0] += 1.5
            }
        }

        return scores.sorted { $0.value > $1.value }.map(\.key)
    }

    /// Build a JSON string suitable for the AI prompt context.
    func preferencesJSON() -> String {
        let ranked = rankedPracticeIDs()
        guard !ranked.isEmpty else { return "[]" }
        let items = ranked.prefix(5).map { "\"\($0)\"" }
        return "[\(items.joined(separator: ", "))]"
    }

    // MARK: - Private

    private func fetchCompletedSessions() -> [PracticeSession] {
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.wasCompleted == true },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func weatherScore(_ weather: InnerWeather) -> Double {
        switch weather {
        case .clear: return 0
        case .cloudy: return 1
        case .stormy: return 2
        }
    }
}
