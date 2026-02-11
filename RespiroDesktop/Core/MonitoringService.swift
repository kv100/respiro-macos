import Foundation

// MARK: - MonitoringService

actor MonitoringService {

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

    // MARK: - Callbacks (Sendable, @MainActor-safe)

    var onWeatherUpdate: (@Sendable (InnerWeather, StressAnalysisResponse) -> Void)?
    var onSilenceDecision: (@Sendable (SilenceDecision) -> Void)?

    // MARK: - Active Hours

    private var activeHoursStart: Int = 9   // 0-23
    private var activeHoursEnd: Int = 18    // 0-23

    // MARK: - Learned Patterns (from DismissalLogger)

    private var learnedPatterns: String?
    private var preferredPracticeIDs: [String] = ["physiological-sigh", "box-breathing"]

    // MARK: - Tool Context (pre-fetched for tool use)

    private var toolContext: ToolContext?

    // MARK: - Constants

    private enum Interval {
        static let base: TimeInterval = 300           // 5 min
        static let stormy: TimeInterval = 180         // 3 min
        static let afterPractice: TimeInterval = 600  // 10 min
        static let afterDismissal: TimeInterval = 900 // 15 min
        static let afterMultipleDismissals: TimeInterval = 1800 // 30 min
        static let maxInterval: TimeInterval = 900    // 15 min
        static let clearMultiplier: Double = 1.5
    }

    // MARK: - Init

    init(screenMonitor: ScreenMonitor, visionClient: ClaudeVisionClient) {
        self.screenMonitor = screenMonitor
        self.visionClient = visionClient
    }

    // MARK: - Public API

    func startMonitoring() {
        guard !isRunning else { return }
        isRunning = true
        currentInterval = Interval.base
        consecutiveClearCount = 0
        dismissalCount = 0

        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            await self?.monitorLoop()
        }
    }

    func stopMonitoring() {
        isRunning = false
        monitorTask?.cancel()
        monitorTask = nil
    }

    /// Perform a single capture + analyze cycle, returns the analysis result.
    /// When effort is .high or .max and tool context is available, uses tool use for practice selection.
    func performSingleCheck() async throws -> StressAnalysisResponse {
        let imageData = try await screenMonitor.captureScreenshot()

        let context = buildContext()
        let effort = EffortLevel.determine(
            recentWeathers: recentEntries.map(\.weather),
            dismissalCount: dismissalCount
        )

        let response: StressAnalysisResponse

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

    /// Emit a silence decision when the AI analyzed but chose not to interrupt.
    func emitSilenceDecision(analysis: StressAnalysisResponse, reason: String) {
        let weather = InnerWeather(rawValue: analysis.weather) ?? .clear
        // Only emit for non-trivial situations (cloudy/stormy, or AI had thinking)
        guard weather != .clear || analysis.thinkingText != nil else { return }

        let thinking = analysis.thinkingText
            ?? "Detected \(weather.displayName.lowercased()) conditions but decided not to interrupt. Reason: \(reason)."

        let decision = SilenceDecision(
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

    /// Update the tool context with pre-fetched user history data.
    /// Call this periodically (e.g., when monitoring starts or after practice completion)
    /// so the tool use loop has fresh data without needing SwiftData access.
    func updateToolContext(_ context: ToolContext) {
        toolContext = context
    }

    func updateActiveHours(start: Int, end: Int) {
        activeHoursStart = max(0, min(23, start))
        activeHoursEnd = max(0, min(23, end))
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
        while !Task.isCancelled && isRunning {
            // Check active hours — skip monitoring if outside window
            if !isWithinActiveHours() {
                // Sleep 5 minutes and re-check
                try? await Task.sleep(nanoseconds: 300_000_000_000)
                continue
            }

            do {
                let response = try await performSingleCheck()

                let weather = InnerWeather(rawValue: response.weather) ?? .clear
                onWeatherUpdate?(weather, response)

                adjustInterval(for: weather)
            } catch {
                // On error, extend interval to avoid hammering API
                currentInterval = max(currentInterval, Interval.afterPractice)
            }

            // Sleep for the current interval
            let sleepNanos = UInt64(currentInterval * 1_000_000_000)
            try? await Task.sleep(nanoseconds: sleepNanos)
        }
    }

    private func isWithinActiveHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        if activeHoursStart <= activeHoursEnd {
            return hour >= activeHoursStart && hour < activeHoursEnd
        } else {
            // Wraps midnight (e.g., 22-06)
            return hour >= activeHoursStart || hour < activeHoursEnd
        }
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

    private func buildContext() -> ScreenshotContext {
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
            learnedPatterns: learnedPatterns
        )
    }
}
