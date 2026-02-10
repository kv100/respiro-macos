import Foundation
import SwiftData

// MARK: - DismissalLogger

@MainActor
final class DismissalLogger {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Log Dismissal

    func logDismissal(
        stressEntryID: UUID,
        aiDetectedWeather: String,
        dismissalType: DismissalType,
        suggestedPracticeID: String?,
        contextSignals: [String]
    ) {
        let event = DismissalEvent(
            stressEntryID: stressEntryID,
            aiDetectedWeather: aiDetectedWeather,
            dismissalType: dismissalType.rawValue,
            suggestedPracticeID: suggestedPracticeID,
            contextSignals: contextSignals
        )
        modelContext.insert(event)
        try? modelContext.save()
    }

    // MARK: - Build Override Patterns for AI Prompt

    func buildLearnedPatterns() -> String? {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let predicate = #Predicate<DismissalEvent> { event in
            event.timestamp >= sevenDaysAgo
        }
        let descriptor = FetchDescriptor<DismissalEvent>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        guard let events = try? modelContext.fetch(descriptor), !events.isEmpty else {
            return nil
        }

        // Aggregate patterns
        var totalDismissals = events.count
        var imFineCount = 0
        var laterCount = 0
        var autoCount = 0
        var weatherCounts: [String: Int] = [:]
        var practiceCounts: [String: Int] = [:]
        var hourCounts: [Int: Int] = [:]

        for event in events {
            switch event.dismissalType {
            case DismissalType.imFine.rawValue:
                imFineCount += 1
            case DismissalType.later.rawValue:
                laterCount += 1
            case DismissalType.autoDismissed.rawValue:
                autoCount += 1
            default:
                break
            }

            weatherCounts[event.aiDetectedWeather, default: 0] += 1

            if let practiceID = event.suggestedPracticeID {
                practiceCounts[practiceID, default: 0] += 1
            }

            let hour = Calendar.current.component(.hour, from: event.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        // Build patterns array
        var patterns: [String] = []

        patterns.append("User dismissed \(totalDismissals) nudges in last 7 days (\(imFineCount) 'I'm Fine', \(laterCount) 'Later', \(autoCount) auto-dismissed)")

        // Time patterns
        let morningDismissals = (6..<12).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
        let afternoonDismissals = (12..<18).reduce(0) { $0 + (hourCounts[$1] ?? 0) }
        let eveningDismissals = (18..<24).reduce(0) { $0 + (hourCounts[$1] ?? 0) }

        if morningDismissals > totalDismissals / 2 {
            patterns.append("User tends to dismiss nudges more in the morning")
        }
        if afternoonDismissals > totalDismissals / 2 {
            patterns.append("User tends to dismiss nudges more in the afternoon")
        }
        if eveningDismissals > totalDismissals / 2 {
            patterns.append("User tends to dismiss nudges more in the evening")
        }

        // Weather false-positive patterns
        if let cloudyDismissals = weatherCounts["cloudy"], cloudyDismissals > 3 {
            patterns.append("User often dismisses 'cloudy' assessments — consider higher confidence threshold for cloudy")
        }

        // Practice rejection patterns
        for (practiceID, count) in practiceCounts where count >= 2 {
            patterns.append("User dismissed '\(practiceID)' suggestions \(count) times — consider alternatives")
        }

        // High im-fine rate
        if imFineCount > totalDismissals * 2 / 3 {
            patterns.append("User frequently says 'I'm Fine' — prefer encouragement over practice nudges, raise confidence threshold")
        }

        return patterns.joined(separator: "; ")
    }

    // MARK: - Dismissal count in recent window

    func dismissalCount(inLast hours: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        let predicate = #Predicate<DismissalEvent> { event in
            event.timestamp >= cutoff
        }
        let descriptor = FetchDescriptor<DismissalEvent>(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
