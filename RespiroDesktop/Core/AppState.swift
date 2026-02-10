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
    @ObservationIgnored @AppStorage("isOnboardingComplete") var isOnboardingComplete: Bool = false

    // MARK: - Monitoring Service

    private var monitoringService: MonitoringService?

    func configureMonitoring(service: MonitoringService) {
        self.monitoringService = service
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
    }

    func notifyPracticeCompleted() async {
        await monitoringService?.onPracticeCompleted()
    }

    func notifyDismissal() async {
        await monitoringService?.onDismissal()
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
