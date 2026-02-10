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

    // MARK: - Callback (Sendable, @MainActor-safe)

    var onWeatherUpdate: (@Sendable (InnerWeather, StressAnalysisResponse) -> Void)?

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
    func performSingleCheck() async throws -> StressAnalysisResponse {
        let imageData = try await screenMonitor.captureScreenshot()

        let context = buildContext()
        let response = try await visionClient.analyzeScreenshot(imageData, context: context)

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
            preferredPractices: ["physiological-sigh", "box-breathing"],
            learnedPatterns: nil
        )
    }
}
