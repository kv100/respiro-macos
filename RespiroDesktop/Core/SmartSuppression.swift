import AppKit
import Foundation

// MARK: - SuppressionResult

enum SuppressionResult: Sendable {
    case allowed
    case neverNow(reason: String)
    case delayFor(seconds: Int, reason: String)
}

// MARK: - SmartSuppression

@MainActor
final class SmartSuppression {

    // Known video call app bundle identifiers
    private static let videoCallBundleIDs: Set<String> = [
        "us.zoom.xos",
        "com.apple.FaceTime",
        "com.microsoft.teams2",
        "com.tinyspeck.slackmacgap",
    ]

    // MARK: - Screen Lock Detection

    private var isScreenLocked: Bool = false

    init() {
        registerForScreenLockNotifications()
    }

    private func registerForScreenLockNotifications() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenLocked = true
            }
        }

        center.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isScreenLocked = false
            }
        }
    }

    // MARK: - Public API

    func shouldSuppress() -> SuppressionResult {
        // 1. Screen locked — NEVER nudge
        if isScreenLocked {
            return .neverNow(reason: "screen_locked")
        }

        // 2. Fullscreen app — NEVER nudge
        if isFrontmostAppFullscreen() {
            return .neverNow(reason: "fullscreen_app")
        }

        // 3. Video call active — NEVER nudge
        if isVideoCallActive() {
            return .neverNow(reason: "video_call_active")
        }

        // 4. Active typing — DELAY 2 min
        if isUserActivelyTyping() {
            return .delayFor(seconds: 120, reason: "active_typing")
        }

        // 5. First 30 min of active hours — DELAY
        if isWithinFirstActiveMinutes() {
            return .delayFor(seconds: 120, reason: "early_active_hours")
        }

        return .allowed
    }

    // MARK: - Detection Methods

    private func isFrontmostAppFullscreen() -> Bool {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        // Check if the frontmost app has a window that occupies the full screen
        // by checking if any window uses the presentationOptions for fullscreen
        let options = NSApplication.shared.currentSystemPresentationOptions
        if options.contains(.fullScreen) {
            return true
        }

        // Also check bundle ID for known presentation apps in fullscreen
        let presentationBundleIDs: Set<String> = [
            "com.apple.Keynote",
            "com.microsoft.Powerpoint",
            "com.google.Chrome",  // Could be in presentation mode
        ]
        if presentationBundleIDs.contains(frontmost.bundleIdentifier ?? "") && options.contains(.hideDock) {
            return true
        }

        return false
    }

    private func isVideoCallActive() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            guard let bundleID = app.bundleIdentifier else { continue }
            if Self.videoCallBundleIDs.contains(bundleID) && !app.isHidden {
                // App is running and visible — likely in a call
                // For FaceTime, being active is enough since you only open it for calls
                if bundleID == "com.apple.FaceTime" && app.isActive {
                    return true
                }
                // For other apps, check if they are the frontmost (active) app
                if app.isActive {
                    return true
                }
            }
        }
        return false
    }

    private func isUserActivelyTyping() -> Bool {
        // Check the time since the last keyboard event using CGEvent
        // If keyboard activity within last 30 seconds, user is typing
        let lastEventTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )
        return lastEventTime < 5.0
    }

    private func isWithinFirstActiveMinutes() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        // Default active hours start at 9. Within first 30 min = 9:00-9:30
        // This is a simple check — could be made configurable via UserPreferences
        let activeHoursStart = 9
        if hour == activeHoursStart && minute < 30 {
            return true
        }
        return false
    }
}
