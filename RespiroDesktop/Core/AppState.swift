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
    @ObservationIgnored @AppStorage("isOnboardingComplete") var isOnboardingComplete: Bool = false

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

    func toggleMonitoring() {
        isMonitoring.toggle()
    }
}
