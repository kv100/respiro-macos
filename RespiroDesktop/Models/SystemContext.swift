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
    let isScreenSharing: Bool
    let systemUptime: TimeInterval
    let idleTime: TimeInterval

    init(
        activeApp: String,
        activeWindowTitle: String?,
        openWindowCount: Int,
        recentAppSwitches: [String],
        pendingNotificationCount: Int,
        isOnVideoCall: Bool,
        isScreenSharing: Bool = false,
        systemUptime: TimeInterval,
        idleTime: TimeInterval
    ) {
        self.activeApp = activeApp
        self.activeWindowTitle = activeWindowTitle
        self.openWindowCount = openWindowCount
        self.recentAppSwitches = recentAppSwitches
        self.pendingNotificationCount = pendingNotificationCount
        self.isOnVideoCall = isOnVideoCall
        self.isScreenSharing = isScreenSharing
        self.systemUptime = systemUptime
        self.idleTime = idleTime
    }

    // Custom decoder: handle missing isScreenSharing in old JSON files
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeApp = try container.decode(String.self, forKey: .activeApp)
        activeWindowTitle = try container.decodeIfPresent(String.self, forKey: .activeWindowTitle)
        openWindowCount = try container.decodeIfPresent(Int.self, forKey: .openWindowCount) ?? 0
        recentAppSwitches = try container.decodeIfPresent([String].self, forKey: .recentAppSwitches) ?? []
        pendingNotificationCount = try container.decodeIfPresent(Int.self, forKey: .pendingNotificationCount) ?? 0
        isOnVideoCall = try container.decodeIfPresent(Bool.self, forKey: .isOnVideoCall) ?? false
        isScreenSharing = try container.decodeIfPresent(Bool.self, forKey: .isScreenSharing) ?? false
        systemUptime = try container.decodeIfPresent(TimeInterval.self, forKey: .systemUptime) ?? 0
        idleTime = try container.decodeIfPresent(TimeInterval.self, forKey: .idleTime) ?? 0
    }
}
