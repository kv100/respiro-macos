import Foundation
import SwiftData

/// Persisted behavior observation for baseline learning.
/// Survives app restarts so baseline can be rebuilt from full history.
@Model
final class BehaviorDataEntry {
    var timestamp: Date
    var contextSwitchesPerMinute: Double
    var sessionDuration: TimeInterval
    var applicationFocus: [String: Double]
    var notificationAccumulation: Int
    var recentAppSequence: [String]

    init(timestamp: Date, metrics: BehaviorMetrics) {
        self.timestamp = timestamp
        self.contextSwitchesPerMinute = metrics.contextSwitchesPerMinute
        self.sessionDuration = metrics.sessionDuration
        self.applicationFocus = metrics.applicationFocus
        self.notificationAccumulation = metrics.notificationAccumulation
        self.recentAppSequence = metrics.recentAppSequence
    }

    /// Reconstruct BehaviorMetrics from stored fields.
    var metrics: BehaviorMetrics {
        BehaviorMetrics(
            contextSwitchesPerMinute: contextSwitchesPerMinute,
            sessionDuration: sessionDuration,
            applicationFocus: applicationFocus,
            notificationAccumulation: notificationAccumulation,
            recentAppSequence: recentAppSequence
        )
    }
}
