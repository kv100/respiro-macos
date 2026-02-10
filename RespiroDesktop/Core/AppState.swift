import SwiftUI

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
        case settings
        case onboarding
    }

    var currentScreen: Screen = .dashboard
    var currentWeather: InnerWeather = .clear
    var isMonitoring: Bool = false
    var lastAnalysis: StressAnalysisResponse?
    var pendingNudge: NudgeDecision?
    @ObservationIgnored @AppStorage("isOnboardingComplete") var isOnboardingComplete: Bool = false

    // MARK: - Services

    private var monitoringService: MonitoringService?
    private var nudgeEngine: NudgeEngine?

    func configureMonitoring(service: MonitoringService) {
        self.monitoringService = service
    }

    func configureNudgeEngine(_ engine: NudgeEngine) {
        self.nudgeEngine = engine
    }

    func startMonitoring() async {
        guard let service = monitoringService else { return }
        isMonitoring = true
        await service.startMonitoring()
    }

    func stopMonitoring() async {
        guard let service = monitoringService else { return }
        isMonitoring = false
        await service.stopMonitoring()
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
            let decision = await engine.shouldNudge(for: analysis)
            self.pendingNudge = decision
            if decision.shouldShow, let nudgeType = decision.nudgeType {
                await engine.recordNudgeShown(type: nudgeType)
                self.showNudge()
            }
        }
    }

    func notifyPracticeCompleted() async {
        await monitoringService?.onPracticeCompleted()
        await nudgeEngine?.recordPracticeCompleted()
    }

    func notifyDismissal() async {
        await monitoringService?.onDismissal()
        await nudgeEngine?.recordDismissal()
    }

    // MARK: - Navigation

    func showDashboard() {
        currentScreen = .dashboard
    }

    func showNudge() {
        currentScreen = .nudge
    }

    func showPractice() {
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

    func showSettings() {
        currentScreen = .settings
    }

    func showOnboarding() {
        currentScreen = .onboarding
    }
}
