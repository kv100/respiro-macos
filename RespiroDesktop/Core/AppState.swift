import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppState {
    enum Screen: Sendable, Equatable {
        case dashboard
        case nudge
        case practice
        case weatherBefore
        case weatherAfter
        case completion
        case whatHelped
        case settings
        case onboarding
        case summary
    }

    var currentScreen: Screen = .dashboard
    var currentWeather: InnerWeather = .clear
    var isMonitoring: Bool = false
    var lastAnalysis: StressAnalysisResponse?
    var pendingNudge: NudgeDecision?
    var selectedWeatherBefore: InnerWeather?
    var selectedWeatherAfter: InnerWeather?
    var completedPracticeCount: Int = 0
    var lastWhatHelped: [String]?
    var lastPracticeCategory: PracticeCategory?
    var selectedPracticeID: String?
    var lastSilenceDecision: SilenceDecision?
    var secondChancePractice: Practice?
    var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "isOnboardingComplete") {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete") }
    }

    // MARK: - Demo Mode

    var isDemoMode: Bool {
        get { demoModeService?.isEnabled ?? false }
        set { demoModeService?.isEnabled = newValue }
    }

    // MARK: - Services

    private var monitoringService: MonitoringService?
    private var nudgeEngine: NudgeEngine?
    private var dismissalLogger: DismissalLogger?
    private var smartSuppression: SmartSuppression?
    private var demoModeService: DemoModeService?

    func configureMonitoring(service: MonitoringService) {
        self.monitoringService = service
    }

    func configureNudgeEngine(_ engine: NudgeEngine) {
        self.nudgeEngine = engine
    }

    func configureDismissalLogger(_ logger: DismissalLogger) {
        self.dismissalLogger = logger
    }

    func configureSmartSuppression(_ suppression: SmartSuppression) {
        self.smartSuppression = suppression
    }

    func configureDemoMode(_ service: DemoModeService) {
        self.demoModeService = service
    }

    func setDemoMode(_ enabled: Bool, modelContext: ModelContext) async {
        guard let service = demoModeService else { return }

        // Update the flag
        service.isEnabled = enabled

        // If enabling, seed demo data
        if enabled {
            service.seedDemoData(modelContext: modelContext)
        }

        // If monitoring is active, restart it with new mode
        if isMonitoring {
            await stopMonitoring()
            await startMonitoring()
        }
    }

    func startMonitoring() async {
        isMonitoring = true

        // Use demo mode if enabled
        if isDemoMode, let demoService = demoModeService {
            let state = self
            demoService.startDemoLoop(
                onUpdate: { @Sendable weather, analysis in
                    Task { @MainActor in
                        state.updateWeather(weather, analysis: analysis)
                    }
                },
                onSilenceDecision: { @Sendable silence in
                    Task { @MainActor in
                        state.lastSilenceDecision = silence
                    }
                }
            )
        } else if let service = monitoringService {
            await service.startMonitoring()
        }
    }

    func stopMonitoring() async {
        isMonitoring = false

        if isDemoMode {
            demoModeService?.stopDemoLoop()
        } else if let service = monitoringService {
            await service.stopMonitoring()
        }
    }

    func toggleMonitoring() async {
        if isMonitoring {
            await stopMonitoring()
        } else {
            await startMonitoring()
        }
    }

    /// Called from MonitoringService callback when new analysis arrives.
    func updateWeather(_ weather: InnerWeather, analysis: StressAnalysisResponse) {
        currentWeather = weather
        lastAnalysis = analysis

        // Evaluate nudge decision asynchronously
        Task { @MainActor [weak self] in
            guard let self, let engine = self.nudgeEngine else { return }

            // Check smart suppression first
            if let suppression = self.smartSuppression {
                let suppressionResult = suppression.shouldSuppress()
                if let denied = engine.evaluateSuppression(suppressionResult) {
                    self.pendingNudge = denied
                    self.captureSilenceDecision(analysis: analysis, reason: denied.reason)
                    return
                }
            }

            let decision = await engine.shouldNudge(for: analysis)
            self.pendingNudge = decision
            if decision.shouldShow, let nudgeType = decision.nudgeType {
                await engine.recordNudgeShown(type: nudgeType)
                self.showNudge()
            } else if !decision.shouldShow {
                self.captureSilenceDecision(analysis: analysis, reason: decision.reason)
            }
        }
    }

    /// Capture a silence decision when the AI chose not to interrupt.
    private func captureSilenceDecision(analysis: StressAnalysisResponse, reason: String) {
        let weather = InnerWeather(rawValue: analysis.weather) ?? .clear
        // Only capture for non-trivial situations
        guard weather != .clear || analysis.nudgeType != nil || analysis.thinkingText != nil else { return }

        let thinking = analysis.thinkingText
            ?? "Detected \(weather.displayName.lowercased()) conditions but chose to stay quiet. Reason: \(reason.replacingOccurrences(of: "_", with: " "))."

        lastSilenceDecision = SilenceDecision(
            thinkingText: thinking,
            effortLevel: analysis.effortLevel ?? .high,
            detectedWeather: weather,
            signals: analysis.signals
        )
    }

    func notifyPracticeCompleted() async {
        await monitoringService?.onPracticeCompleted()
        await nudgeEngine?.recordPracticeCompleted()
    }

    func notifyDismissal(type: DismissalType = .imFine) async {
        await monitoringService?.onDismissal()
        await nudgeEngine?.recordDismissal()

        // Log to SwiftData and update learned patterns for AI
        if let logger = dismissalLogger, let analysis = lastAnalysis {
            logger.logDismissal(
                stressEntryID: UUID(), // Will be linked to actual entry when available
                aiDetectedWeather: analysis.weather,
                dismissalType: type,
                suggestedPracticeID: analysis.suggestedPracticeID,
                contextSignals: analysis.signals
            )

            // Rebuild learned patterns and feed to monitoring service
            let patterns = logger.buildLearnedPatterns()
            await monitoringService?.updateLearnedPatterns(patterns)
        }
    }

    // MARK: - Navigation

    func showDashboard() {
        currentScreen = .dashboard
    }

    func showNudge() {
        currentScreen = .nudge
    }

    func showPractice() {
        if selectedPracticeID == nil, let suggested = pendingNudge?.suggestedPracticeID {
            selectedPracticeID = suggested
        }
        currentScreen = .practice
    }

    func showWeatherBefore() {
        currentScreen = .weatherBefore
    }

    func showWeatherAfter() {
        currentScreen = .weatherAfter
    }

    func showCompletion() {
        currentScreen = .completion
    }

    func showWhatHelped() {
        currentScreen = .whatHelped
    }

    func showSettings() {
        currentScreen = .settings
    }

    func showOnboarding() {
        currentScreen = .onboarding
    }

    func showSummary() {
        currentScreen = .summary
    }
}
