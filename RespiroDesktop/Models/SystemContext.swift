import Foundation

/// System-level context at the time of screenshot capture.
/// Provides additional signals beyond visual content for stress detection.
struct SystemContext: Sendable, Codable {
    let activeApp: String
    let activeWindowTitle: String?
    let openWindowCount: Int
    let recentAppSwitches: [String]
    let pendingNotificationCount: Int
    let isOnVideoCall: Bool
    let systemUptime: TimeInterval
    let idleTime: TimeInterval

    init(
        activeApp: String,
        activeWindowTitle: String?,
        openWindowCount: Int,
        recentAppSwitches: [String],
        pendingNotificationCount: Int,
        isOnVideoCall: Bool,
        systemUptime: TimeInterval,
        idleTime: TimeInterval
    ) {
        self.activeApp = activeApp
        self.activeWindowTitle = activeWindowTitle
        self.openWindowCount = openWindowCount
        self.recentAppSwitches = recentAppSwitches
        self.pendingNotificationCount = pendingNotificationCount
        self.isOnVideoCall = isOnVideoCall
        self.systemUptime = systemUptime
        self.idleTime = idleTime
    }
}
