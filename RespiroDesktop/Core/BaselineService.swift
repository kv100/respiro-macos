import Foundation
import SwiftData

// MARK: - Baseline Service

/// Learns user's behavioral baseline from 7+ days of history to detect stress-indicating deviations.
/// All behavior data is persisted in SwiftData so learning survives app restarts.
actor BaselineService {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - State

    private var currentBaseline: UserBaseline?

    // MARK: - Constants

    private enum Config {
        static let minDaysForBaseline = 7
        static let maxHistoryDays = 30
        static let deviationThreshold = 1.5
    }

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadBaseline()
        }
    }

    // MARK: - Public API

    /// Record a new behavior data point for baseline learning.
    func recordBehavior(_ metrics: BehaviorMetrics, at time: Date) async {
        let entry = BehaviorDataEntry(timestamp: time, metrics: metrics)
        modelContext.insert(entry)
        try? modelContext.save()

        // Prune entries older than 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -Config.maxHistoryDays, to: Date()) ?? Date()
        let oldDescriptor = FetchDescriptor<BehaviorDataEntry>(
            predicate: #Predicate { $0.timestamp < cutoff }
        )
        if let oldEntries = try? modelContext.fetch(oldDescriptor) {
            for old in oldEntries {
                modelContext.delete(old)
            }
            try? modelContext.save()
        }

        // Rebuild baseline if we have enough data
        let countDescriptor = FetchDescriptor<BehaviorDataEntry>()
        let totalCount = (try? modelContext.fetchCount(countDescriptor)) ?? 0
        if totalCount >= Config.minDaysForBaseline * 12 {
            await rebuildBaseline()
        }
    }

    /// Get current baseline, if available (nil if < 7 days of data).
    func getCurrentBaseline() -> UserBaseline? {
        return currentBaseline
    }

    /// Calculate deviation from baseline for current metrics.
    /// Returns nil if no baseline exists yet.
    /// Returns 0.0-2.0+ where:
    /// - 0.0 = normal
    /// - 1.0 = moderate deviation (1x baseline)
    /// - 1.5+ = high deviation (stress signal)
    func calculateDeviation(current: BehaviorMetrics) -> Double? {
        guard let baseline = currentBaseline else { return nil }

        var deviations: [Double] = []

        // Context switches (higher = more stress)
        if baseline.avgContextSwitchRate > 0 {
            let switchDeviation = current.contextSwitchesPerMinute / baseline.avgContextSwitchRate
            deviations.append(switchDeviation)
        }

        // Session length (longer = more stress, but only if significantly longer)
        if baseline.typicalSessionLength > 0 {
            let sessionDeviation = current.sessionDuration / baseline.typicalSessionLength
            if sessionDeviation > 1.0 {
                deviations.append(sessionDeviation)
            }
        }

        // App focus deviation (how different is current app mix from normal?)
        let focusDeviation = calculateFocusDeviation(
            current: current.applicationFocus,
            baseline: baseline.normalAppMix
        )
        deviations.append(focusDeviation)

        return deviations.max() ?? 0.0
    }

    /// Rebuild baseline from persisted history.
    func rebuildBaseline() async {
        let cutoff = Calendar.current.date(byAdding: .day, value: -Config.maxHistoryDays, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<BehaviorDataEntry>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              entries.count >= Config.minDaysForBaseline * 12 else { return }

        let userID = DeviceID.current
        let baseline = UserBaseline(userID: userID)

        // Calculate averages
        let contextSwitches = entries.map(\.contextSwitchesPerMinute)
        baseline.avgContextSwitchRate = contextSwitches.reduce(0, +) / Double(contextSwitches.count)

        let sessionLengths = entries.map(\.sessionDuration)
        baseline.typicalSessionLength = sessionLengths.reduce(0, +) / Double(sessionLengths.count)

        // Build normal app mix (weighted average of all app focus patterns)
        var appMixAccumulator: [String: Double] = [:]
        for entry in entries {
            for (app, percentage) in entry.applicationFocus {
                appMixAccumulator[app, default: 0.0] += percentage
            }
        }
        for key in appMixAccumulator.keys {
            appMixAccumulator[key]? /= Double(entries.count)
        }
        baseline.normalAppMix = appMixAccumulator

        // Build weekday patterns (stress level by day of week)
        var weekdayAccumulator: [Int: [Double]] = [:]
        for entry in entries {
            let weekday = Calendar.current.component(.weekday, from: entry.timestamp)
            weekdayAccumulator[weekday, default: []].append(entry.contextSwitchesPerMinute)
        }
        for (weekday, values) in weekdayAccumulator {
            baseline.weekdayPattern[weekday] = values.reduce(0, +) / Double(values.count)
        }

        // Build time-of-day patterns (stress level by hour)
        var hourAccumulator: [Int: [Double]] = [:]
        for entry in entries {
            let hour = Calendar.current.component(.hour, from: entry.timestamp)
            hourAccumulator[hour, default: []].append(entry.contextSwitchesPerMinute)
        }
        for (hour, values) in hourAccumulator {
            baseline.timeOfDayPattern[hour] = values.reduce(0, +) / Double(values.count)
        }

        baseline.lastUpdated = Date()

        // Delete old baselines for this user before inserting new one
        let oldDescriptor = FetchDescriptor<UserBaseline>(
            predicate: #Predicate { $0.userID == userID }
        )
        if let oldBaselines = try? modelContext.fetch(oldDescriptor) {
            for old in oldBaselines {
                modelContext.delete(old)
            }
        }

        modelContext.insert(baseline)
        try? modelContext.save()

        currentBaseline = baseline
    }

    // MARK: - Private Helpers

    private func loadBaseline() async {
        let userID = DeviceID.current
        let descriptor = FetchDescriptor<UserBaseline>(
            predicate: #Predicate { $0.userID == userID },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )

        if let baseline = try? modelContext.fetch(descriptor).first {
            currentBaseline = baseline
        }
    }

    private func calculateFocusDeviation(current: [String: Double], baseline: [String: Double]) -> Double {
        var totalDifference = 0.0

        let allApps = Set(current.keys).union(Set(baseline.keys))
        for app in allApps {
            let currentFocus = current[app] ?? 0.0
            let baselineFocus = baseline[app] ?? 0.0
            totalDifference += abs(currentFocus - baselineFocus)
        }

        return min(totalDifference, 2.0)
    }
}
