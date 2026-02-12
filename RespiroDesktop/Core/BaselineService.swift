import Foundation
import SwiftData

// MARK: - Baseline Service

/// Learns user's behavioral baseline from 7+ days of history to detect stress-indicating deviations.
/// Uses historical BehaviorMetrics to build a personalized normal range.
actor BaselineService {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - State

    private var currentBaseline: UserBaseline?
    private var behaviorHistory: [BehaviorDataPoint] = []

    // MARK: - Constants

    private enum Config {
        static let minDaysForBaseline = 7
        static let maxHistoryDays = 30
        static let deviationThreshold = 1.5 // 1.5x baseline = stress signal
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
        let dataPoint = BehaviorDataPoint(
            timestamp: time,
            metrics: metrics
        )
        behaviorHistory.append(dataPoint)

        // Keep only last 30 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -Config.maxHistoryDays, to: Date()) ?? Date()
        behaviorHistory.removeAll { $0.timestamp < cutoff }

        // Rebuild baseline if we have enough data
        if behaviorHistory.count >= Config.minDaysForBaseline * 12 { // ~12 samples/day
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

        // Calculate deviation across multiple dimensions
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

        // Return max deviation (most stressed dimension)
        return deviations.max() ?? 0.0
    }

    /// Rebuild baseline from accumulated history.
    /// Called automatically when enough data points exist.
    func rebuildBaseline() async {
        guard behaviorHistory.count >= Config.minDaysForBaseline * 12 else { return }

        let userID = DeviceID.current
        let baseline = UserBaseline(userID: userID)

        // Calculate averages
        let contextSwitches = behaviorHistory.map(\.metrics.contextSwitchesPerMinute)
        baseline.avgContextSwitchRate = contextSwitches.reduce(0, +) / Double(contextSwitches.count)

        let sessionLengths = behaviorHistory.map(\.metrics.sessionDuration)
        baseline.typicalSessionLength = sessionLengths.reduce(0, +) / Double(sessionLengths.count)

        // Build normal app mix (weighted average of all app focus patterns)
        var appMixAccumulator: [String: Double] = [:]
        for point in behaviorHistory {
            for (app, percentage) in point.metrics.applicationFocus {
                appMixAccumulator[app, default: 0.0] += percentage
            }
        }
        for key in appMixAccumulator.keys {
            appMixAccumulator[key]? /= Double(behaviorHistory.count)
        }
        baseline.normalAppMix = appMixAccumulator

        // Build weekday patterns (stress level by day of week)
        var weekdayAccumulator: [Int: [Double]] = [:]
        for point in behaviorHistory {
            let weekday = Calendar.current.component(.weekday, from: point.timestamp)
            weekdayAccumulator[weekday, default: []].append(point.metrics.contextSwitchesPerMinute)
        }
        for (weekday, values) in weekdayAccumulator {
            baseline.weekdayPattern[weekday] = values.reduce(0, +) / Double(values.count)
        }

        // Build time-of-day patterns (stress level by hour)
        var hourAccumulator: [Int: [Double]] = [:]
        for point in behaviorHistory {
            let hour = Calendar.current.component(.hour, from: point.timestamp)
            hourAccumulator[hour, default: []].append(point.metrics.contextSwitchesPerMinute)
        }
        for (hour, values) in hourAccumulator {
            baseline.timeOfDayPattern[hour] = values.reduce(0, +) / Double(values.count)
        }

        baseline.lastUpdated = Date()

        // Persist to SwiftData
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
        // Calculate how different the current app focus is from baseline
        // Uses simple distance metric: sum of absolute differences
        var totalDifference = 0.0

        let allApps = Set(current.keys).union(Set(baseline.keys))
        for app in allApps {
            let currentFocus = current[app] ?? 0.0
            let baselineFocus = baseline[app] ?? 0.0
            totalDifference += abs(currentFocus - baselineFocus)
        }

        // Normalize: 0.0 = identical, 2.0 = completely different
        return min(totalDifference, 2.0)
    }
}

// MARK: - Data Point

/// Single behavior observation with timestamp.
/// Stored in-memory, not persisted (only baseline is persisted).
private struct BehaviorDataPoint: Sendable {
    let timestamp: Date
    let metrics: BehaviorMetrics
}
