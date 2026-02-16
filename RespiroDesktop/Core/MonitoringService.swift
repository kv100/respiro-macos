import Foundation
import AppKit
import OSLog

// MARK: - MonitoringService

actor MonitoringService {
    private let logger = Logger(subsystem: "com.respiro.desktop", category: "Monitoring")

    // MARK: - Dependencies

    private let screenMonitor: ScreenMonitor
    private let visionClient: ClaudeVisionClient

    // MARK: - State

    private var isRunning: Bool = false
    private var currentInterval: TimeInterval = 300 // 5 min base
    private var consecutiveClearCount: Int = 0
    private var recentEntries: [StressAnalysisResponse] = [] // last 3
    private var dismissalCount: Int = 0
    private var monitorTask: Task<Void, Never>?
    private var lastScreenshotTime: Date?

    // MARK: - Behavior Tracking State

    private var appSwitchHistory: [(app: String, timestamp: Date)] = []
    private var sessionStartTime: Date?
    private var lastContextUpdate: Date = Date()

    // MARK: - Callbacks (Sendable, @MainActor-safe)

    var onWeatherUpdate: (@Sendable (InnerWeather, StressAnalysisResponse) -> Void)?
    var onSilenceDecision: (@Sendable (SilenceDecision) -> Void)?
    var onDiagnostic: (@Sendable (String) -> Void)?
    var onAutoPause: (@Sendable () -> Void)?

    // MARK: - Idle Detection

    private let autoPauseIdleThreshold: TimeInterval = 30 * 60 // 30 min

    /// Check if user has been idle (no keyboard/mouse) for longer than threshold
    private nonisolated func userIdleTime() -> TimeInterval {
        let keyboard = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        let mouse = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let click = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .leftMouseDown)
        return min(keyboard, mouse, click)
    }

    // Active hours removed — monitor whenever app is running

    // MARK: - Learned Patterns (from DismissalLogger)

    private var learnedPatterns: String?
    private var preferredPracticeIDs: [String] = [
        "physiological-sigh", "box-breathing", "extended-exhale",
        "grounding-54321", "stop-technique", "body-scan",
    ]

    // MARK: - False Positive Patterns (from NudgeEngine)

    private var falsePositivePatterns: [String] = []

    // MARK: - Tool Context (pre-fetched for tool use)

    private var toolContext: ToolContext?

    // MARK: - Constants

    private enum Interval {
        static let base: TimeInterval = 300           // 5 min
        static let stormy: TimeInterval = 180         // 3 min
        static let afterPractice: TimeInterval = 600  // 10 min
        static let afterDismissal: TimeInterval = 900 // 15 min
        static let afterMultipleDismissals: TimeInterval = 900 // 15 min (hard cap)
        static let maxInterval: TimeInterval = 900    // 15 min absolute max
        static let clearMultiplier: Double = 1.5
    }

    // MARK: - Privacy: Sensitive App Detection

    private static let defaultSensitiveApps: Set<String> = [
        "com.agilebits.onepassword",   // 1Password
        "com.apple.keychainaccess",     // Keychain Access
        "com.lastpass.LastPass",        // LastPass
        "com.bitwarden.desktop",        // Bitwarden
        "com.dashlane.Dashlane",        // Dashlane
        "com.apple.systempreferences",  // System Settings (may show passwords)
    ]

    private func isSensitiveAppActive() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        let bundleID = frontApp.bundleIdentifier ?? ""
        let appName = frontApp.localizedName ?? ""

        // Check hardcoded bundle ID prefixes
        if Self.defaultSensitiveApps.contains(where: { bundleID.hasPrefix($0) }) {
            return true
        }

        // Check user-excluded apps by name
        let userExcluded = UserDefaults.standard.stringArray(forKey: "respiro_excluded_apps") ?? []
        return userExcluded.contains(appName)
    }

    // MARK: - Init

    init(screenMonitor: ScreenMonitor, visionClient: ClaudeVisionClient) {
        self.screenMonitor = screenMonitor
        self.visionClient = visionClient
    }

    // MARK: - Public API

    func startMonitoring() {
        guard !isRunning else {
            logger.debug("⚠️ startMonitoring called but already running")
            return
        }

        // Debounce: if last screenshot was < 60 seconds ago, resume without resetting state
        if let last = lastScreenshotTime, Date().timeIntervalSince(last) < 60 {
            logger.debug("🔄 Resuming (debounce, last screenshot \(Int(Date().timeIntervalSince(last)))s ago)")
            isRunning = true
            monitorTask?.cancel()
            monitorTask = Task { await self.monitorLoop() }
            return
        }

        logger.debug("▶️ Starting monitoring fresh. Interval: \(Int(Interval.base))s")
        isRunning = true
        currentInterval = Interval.base
        consecutiveClearCount = 0
        dismissalCount = 0

        startAppSwitchTracking()

        monitorTask?.cancel()
        monitorTask = Task { await self.monitorLoop() }
    }

    func stopMonitoring() {
        isRunning = false
        monitorTask?.cancel()
        monitorTask = nil
        stopAppSwitchTracking()
    }

    /// Subscribe to NSWorkspace app activation notifications for real-time context switch tracking.
    /// Uses nonisolated(unsafe) observer storage since NotificationCenter requires main thread.
    private nonisolated(unsafe) static var _workspaceObserver: Any?

    private func startAppSwitchTracking() {
        stopAppSwitchTracking()
        let monitor = self
        logger.debug("👀 Setting up NSWorkspace app switch observer")
        // MUST use NSWorkspace.shared.notificationCenter (not NotificationCenter.default)
        MonitoringService._workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let app = (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.localizedName else { return }
            Task { await monitor.recordAppSwitch(app) }
        }
    }

    private func stopAppSwitchTracking() {
        if let observer = MonitoringService._workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            MonitoringService._workspaceObserver = nil
        }
    }

    /// Record an app switch from NSWorkspace notification
    private func recordAppSwitch(_ app: String) {
        // Only record if different from last app (avoid duplicates)
        if appSwitchHistory.last?.app != app {
            logger.fault("🔀 App switch: \(app) (history: \(self.appSwitchHistory.count))")
            appSwitchHistory.append((app, Date()))
        }
        // Keep only last hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        appSwitchHistory = appSwitchHistory.filter { $0.timestamp > oneHourAgo }
    }

    /// Perform a single capture + analyze cycle, returns the analysis result.
    /// When effort is .high or .max and tool context is available, uses tool use for practice selection.
    func performSingleCheck() async throws -> StressAnalysisResponse {
        // Privacy: skip capture when sensitive app (password manager, etc.) is active
        if isSensitiveAppActive() {
            logger.debug("🔒 Skipping capture — sensitive app active")
            let skipResponse = StressAnalysisResponse(
                weather: "clear",
                confidence: 1.0,
                signals: ["sensitive_app_active"],
                nudgeType: "none",
                nudgeMessage: nil,
                suggestedPracticeID: nil
            )
            recordResponse(skipResponse)
            return skipResponse
        }

        // Privacy: skip capture when screen is being shared
        let preContext = collectSystemContext()
        if preContext.isScreenSharing {
            logger.debug("🔒 Skipping capture — screen sharing detected")
            let skipResponse = StressAnalysisResponse(
                weather: "clear",
                confidence: 1.0,
                signals: ["screen_sharing_active"],
                nudgeType: "none",
                nudgeMessage: nil,
                suggestedPracticeID: nil
            )
            recordResponse(skipResponse)
            return skipResponse
        }

        let imageData = try await screenMonitor.captureScreenshot()

        // Collect behavioral metrics and system context
        let behaviorMetrics = buildBehaviorMetrics()
        let systemContext = collectSystemContext()

        // Calculate baseline deviation (if BaselineService available)
        let baselineDeviation: Double? = nil  // TODO: integrate BaselineService

        let context = buildContext(
            behaviorMetrics: behaviorMetrics,
            systemContext: systemContext,
            baselineDeviation: baselineDeviation
        )

        let effort = EffortLevel.determine(
            recentWeathers: recentEntries.map(\.weather),
            dismissalCount: dismissalCount
        )

        var response: StressAnalysisResponse

        // Use tool use for high/max effort when we might need practice selection
        if effort != .low, let toolCtx = toolContext {
            response = try await visionClient.analyzeScreenshotWithTools(
                imageData,
                context: context,
                effortLevel: effort,
                toolContext: toolCtx
            )
        } else {
            response = try await visionClient.analyzeScreenshot(imageData, context: context, effortLevel: effort)
        }

        // Attach behavioral context to response for NudgeEngine
        response.behaviorMetrics = behaviorMetrics
        response.baselineDeviation = baselineDeviation
        response.systemContext = systemContext
        logger.fault("📎 Attached metrics: switches=\(String(format: "%.1f", behaviorMetrics.contextSwitchesPerMinute), privacy: .public)/min, session=\(Int(behaviorMetrics.sessionDuration), privacy: .public)s, apps=\(behaviorMetrics.applicationFocus.count, privacy: .public), metricsNil=\(response.behaviorMetrics == nil, privacy: .public)")

        recordResponse(response)
        return response
    }

    // MARK: - Interval Adjustment Hooks

    func onPracticeCompleted() {
        currentInterval = Interval.afterPractice
        consecutiveClearCount = 0
        dismissalCount = 0
    }

    func onDismissal() {
        dismissalCount += 1
        if dismissalCount >= 3 {
            currentInterval = Interval.afterMultipleDismissals
        } else {
            currentInterval = Interval.afterDismissal
        }
    }

    func setWeatherCallback(_ callback: @escaping @Sendable (InnerWeather, StressAnalysisResponse) -> Void) {
        onWeatherUpdate = callback
    }

    func setSilenceCallback(_ callback: @escaping @Sendable (SilenceDecision) -> Void) {
        onSilenceDecision = callback
    }

    func setDiagnosticCallback(_ callback: @escaping @Sendable (String) -> Void) {
        onDiagnostic = callback
    }

    func setAutoPauseCallback(_ callback: @escaping @Sendable () -> Void) {
        onAutoPause = callback
    }

    /// Emit a silence decision when the AI analyzed but chose not to interrupt.
    func emitSilenceDecision(analysis: StressAnalysisResponse, reason: String) {
        let weather = InnerWeather(rawValue: analysis.weather) ?? .clear
        // Only emit for non-trivial situations (cloudy/stormy, or AI had thinking)
        guard weather != .clear || analysis.thinkingText != nil else { return }

        let thinking = analysis.thinkingText
            ?? "Detected \(weather.displayName.lowercased()) conditions but decided not to interrupt. Reason: \(reason)."

        let decision = SilenceDecision(
            reason: reason,
            thinkingText: thinking,
            effortLevel: analysis.effortLevel ?? .high,
            detectedWeather: weather,
            signals: analysis.signals
        )
        onSilenceDecision?(decision)
    }

    func updateLearnedPatterns(_ patterns: String?) {
        learnedPatterns = patterns
    }

    func updatePreferredPractices(_ practiceIDs: [String]) {
        if !practiceIDs.isEmpty {
            preferredPracticeIDs = practiceIDs
        }
    }

    func updateFalsePositivePatterns(_ patterns: [String]) {
        falsePositivePatterns = patterns
    }

    /// Update the tool context with pre-fetched user history data.
    /// Call this periodically (e.g., when monitoring starts or after practice completion)
    /// so the tool use loop has fresh data without needing SwiftData access.
    func updateToolContext(_ context: ToolContext) {
        toolContext = context
    }

    // Active hours removed — app monitors whenever running

    /// Reset session state after wake-from-sleep or long gap.
    /// Clears all accumulated behavioral data so the new session starts fresh.
    func resetSession() {
        let oldDuration: TimeInterval
        if let start = sessionStartTime {
            oldDuration = Date().timeIntervalSince(start)
        } else {
            oldDuration = 0
        }
        logger.fault("🔄 Resetting session (was \(Int(oldDuration))s). Clearing behavioral state.")
        sessionStartTime = Date()
        appSwitchHistory = []
        recentEntries = []
        consecutiveClearCount = 0
        dismissalCount = 0
        lastScreenshotTime = nil
        currentInterval = Interval.base
    }

    /// Trigger an immediate check (e.g., after wake from sleep).
    func triggerImmediateCheck() async {
        guard isRunning else { return }
        do {
            let response = try await performSingleCheck()
            let weather = InnerWeather(rawValue: response.weather) ?? .clear
            onWeatherUpdate?(weather, response)
        } catch {
            // Silently handle — wake check is best-effort
        }
    }

    // MARK: - Read-only accessors

    var interval: TimeInterval {
        currentInterval
    }

    var running: Bool {
        isRunning
    }

    // MARK: - Private

    private func monitorLoop() async {
        logger.debug("⏱ Monitor loop started. lastScreenshot: \(self.lastScreenshotTime?.description ?? "nil"), interval: \(Int(self.currentInterval))s")

        // On resume after recent screenshot, skip to sleep. On fresh start, short delay.
        if let last = lastScreenshotTime, Date().timeIntervalSince(last) < currentInterval {
            let remaining = currentInterval - Date().timeIntervalSince(last)
            logger.debug("⏱ Resuming, waiting \(Int(remaining))s remaining")
            try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
        } else if lastScreenshotTime == nil {
            logger.debug("⏱ First screenshot in 10s")
            try? await Task.sleep(nanoseconds: 10_000_000_000)
        }

        while !Task.isCancelled && isRunning {
            // Auto-pause if user has been idle for 30+ minutes (e.g., sleeping, away)
            let idle = userIdleTime()
            if idle >= autoPauseIdleThreshold {
                logger.fault("😴 User idle for \(Int(idle))s — auto-pausing monitoring")
                onDiagnostic?("Auto-paused (inactive)")
                isRunning = false
                onAutoPause?()
                return
            }

            logger.fault("📸 Taking screenshot...")
            onDiagnostic?("Analyzing...")
            let checkStart = Date()
            do {
                let response = try await performSingleCheck()
                let elapsed = Date().timeIntervalSince(checkStart)
                lastScreenshotTime = Date()

                let weather = InnerWeather(rawValue: response.weather) ?? .clear
                let nextMin = Int(currentInterval / 60)
                logger.fault("📸 Check complete: \(response.weather, privacy: .public) (took \(String(format: "%.1f", elapsed), privacy: .public)s). Next in \(Int(self.currentInterval), privacy: .public)s")
                onDiagnostic?("\(response.weather) — next in \(nextMin)m")
                onWeatherUpdate?(weather, response)

                adjustInterval(for: weather)
            } catch {
                let elapsed = Date().timeIntervalSince(checkStart)
                let errMsg = error.localizedDescription
                logger.fault("❌ Check failed after \(String(format: "%.1f", elapsed), privacy: .public)s: \(errMsg, privacy: .public). Interval now \(Int(self.currentInterval), privacy: .public)s")
                onDiagnostic?("Error: \(errMsg.prefix(50))")
                currentInterval = max(currentInterval, Interval.afterPractice)
            }

            // Sleep for the current interval
            let sleepMin = Int(currentInterval / 60)
            logger.fault("💤 Sleeping \(Int(self.currentInterval))s")
            onDiagnostic?("Waiting \(sleepMin)m...")
            let expectedInterval = currentInterval
            let sleepStart = Date()
            let sleepNanos = UInt64(currentInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: sleepNanos)

            // Detect sleep gap: if actual elapsed time >> expected, Mac was sleeping
            let actualElapsed = Date().timeIntervalSince(sleepStart)
            if actualElapsed > expectedInterval * 2 {
                logger.fault("🔄 Sleep gap detected: expected \(Int(expectedInterval))s, actual \(Int(actualElapsed))s — resetting session")
                resetSession()
                onDiagnostic?("Session reset (wake)")
            }
        }
        logger.debug("⏱ Monitor loop ended. isRunning=\(self.isRunning), cancelled=\(Task.isCancelled)")
    }

    private func recordResponse(_ response: StressAnalysisResponse) {
        recentEntries.append(response)
        if recentEntries.count > 3 {
            recentEntries.removeFirst()
        }
    }

    private func adjustInterval(for weather: InnerWeather) {
        switch weather {
        case .clear:
            consecutiveClearCount += 1
            if consecutiveClearCount >= 3 {
                currentInterval = min(currentInterval * Interval.clearMultiplier, Interval.maxInterval)
            } else {
                currentInterval = Interval.base
            }
        case .cloudy:
            consecutiveClearCount = 0
            currentInterval = Interval.base
        case .stormy:
            consecutiveClearCount = 0
            currentInterval = Interval.stormy
        }
    }

    // MARK: - Behavior Tracking Methods

    /// Calculate context switches per minute over the last 5 minutes
    /// Counts actual app transitions (each switch from app A to app B = 1 switch)
    private func calculateContextSwitchRate() -> Double {
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let recentSwitches = appSwitchHistory.filter { $0.timestamp > fiveMinutesAgo }

        // Each entry is already a unique switch (deduped in recordAppSwitch)
        // So count = number of transitions
        let switches = max(0, recentSwitches.count - 1)
        guard switches > 0 else { return 0 }

        // Calculate actual time window for accurate rate
        if let first = recentSwitches.first?.timestamp, let last = recentSwitches.last?.timestamp {
            let windowMinutes = max(1.0, last.timeIntervalSince(first) / 60.0)
            return Double(switches) / windowMinutes
        }
        return Double(switches) / 5.0
    }

    /// Collect system context at the time of screenshot
    private func collectSystemContext() -> SystemContext {
        let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]
        let windowCount = windowList?.filter { window in
            let layer = window[kCGWindowLayer as String] as? Int ?? -1
            let name = window[kCGWindowOwnerName as String] as? String ?? ""
            // Layer 0 = normal application windows; exclude system processes
            return layer == 0 && !name.isEmpty && name != "Window Server" && name != "Dock"
        }.count ?? 0

        let recentApps = appSwitchHistory.suffix(10).map { $0.app }

        // Check for video call apps
        let runningApps = NSWorkspace.shared.runningApplications.map { $0.localizedName ?? "" }
        let videoCallApps = ["Zoom", "Microsoft Teams", "Google Meet", "FaceTime", "Skype"]
        let isOnVideoCall = runningApps.contains(where: { videoCallApps.contains($0) })

        // Detect screen sharing via CGDisplayStream or common screen sharing indicators
        let screenSharingBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        let screenSharingApps: Set<String> = [
            "com.apple.ScreenSharing",
            "us.zoom.xos",  // Zoom screen share
            "com.microsoft.teams",
        ]
        // Also check if any display is being mirrored
        let isScreenSharing = !screenSharingApps.isDisjoint(with: screenSharingBundleIDs)

        return SystemContext(
            activeApp: activeApp,
            activeWindowTitle: nil,  // TODO: AXUIElement API for window title
            openWindowCount: windowCount,
            recentAppSwitches: Array(recentApps),
            pendingNotificationCount: 0,  // TODO: UNUserNotificationCenter
            isOnVideoCall: isOnVideoCall,
            isScreenSharing: isScreenSharing,
            systemUptime: ProcessInfo.processInfo.systemUptime,
            idleTime: 0  // TODO: CGEventSource for idle time
        )
    }

    /// Build behavior metrics from tracked data
    private func buildBehaviorMetrics() -> BehaviorMetrics {
        let contextSwitchRate = calculateContextSwitchRate()

        let sessionDuration: TimeInterval
        if let start = sessionStartTime {
            sessionDuration = Date().timeIntervalSince(start)
        } else {
            sessionStartTime = Date()
            sessionDuration = 0
        }

        // Calculate app focus percentages
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let recentSwitches = appSwitchHistory.filter { $0.timestamp > fiveMinutesAgo }

        var appDurations: [String: TimeInterval] = [:]
        for i in 0..<recentSwitches.count {
            let current = recentSwitches[i]
            let nextTime = i + 1 < recentSwitches.count ? recentSwitches[i + 1].timestamp : Date()
            let duration = nextTime.timeIntervalSince(current.timestamp)
            appDurations[current.app, default: 0] += duration
        }

        let totalTime = appDurations.values.reduce(0, +)
        let appFocus = appDurations.mapValues { totalTime > 0 ? $0 / totalTime : 0 }

        return BehaviorMetrics(
            contextSwitchesPerMinute: contextSwitchRate,
            sessionDuration: sessionDuration,
            applicationFocus: appFocus,
            notificationAccumulation: 0,  // TODO: track notifications
            recentAppSequence: recentSwitches.suffix(5).map { $0.app }
        )
    }

    private func buildContext(
        behaviorMetrics: BehaviorMetrics?,
        systemContext: SystemContext?,
        baselineDeviation: Double?
    ) -> ScreenshotContext {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let time = formatter.string(from: Date())

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let day = dayFormatter.string(from: Date())

        // Build recent entries JSON
        let entriesJSON: String
        if recentEntries.isEmpty {
            entriesJSON = "[]"
        } else {
            let entries = recentEntries.map { entry in
                "{\"weather\":\"\(entry.weather)\",\"confidence\":\(entry.confidence)}"
            }
            entriesJSON = "[\(entries.joined(separator: ","))]"
        }

        return ScreenshotContext(
            time: time,
            dayOfWeek: day,
            recentEntries: entriesJSON,
            lastNudgeMinutesAgo: nil,
            lastNudgeType: nil,
            dismissalCount2h: dismissalCount,
            preferredPractices: preferredPracticeIDs,
            learnedPatterns: learnedPatterns,
            behaviorMetrics: behaviorMetrics,
            systemContext: systemContext,
            baselineDeviation: baselineDeviation,
            falsePositivePatterns: falsePositivePatterns.isEmpty ? nil : falsePositivePatterns
        )
    }
}
