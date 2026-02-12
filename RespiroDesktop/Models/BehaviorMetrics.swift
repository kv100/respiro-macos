import Foundation

/// Behavioral metrics capturing user's interaction patterns.
/// Used to detect stress signals beyond visual screenshot analysis.
struct BehaviorMetrics: Sendable, Codable {
    let contextSwitchesPerMinute: Double
    let sessionDuration: TimeInterval
    let applicationFocus: [String: Double]  // app name -> percentage
    let notificationAccumulation: Int
    let recentAppSequence: [String]

    init(
        contextSwitchesPerMinute: Double,
        sessionDuration: TimeInterval,
        applicationFocus: [String: Double],
        notificationAccumulation: Int,
        recentAppSequence: [String]
    ) {
        self.contextSwitchesPerMinute = contextSwitchesPerMinute
        self.sessionDuration = sessionDuration
        self.applicationFocus = applicationFocus
        self.notificationAccumulation = notificationAccumulation
        self.recentAppSequence = recentAppSequence
    }
}
