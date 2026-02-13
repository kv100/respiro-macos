import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState

    private var practiceType: PracticeType {
        if let id = appState.selectedPracticeID,
           let type = PracticeType(rawValue: id) {
            return type
        }
        return .physiologicalSigh
    }

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
            } else if appState.showWeatherCheckIn {
                WeatherCheckInView(
                    onSelect: { weather in appState.completeWeatherCheckIn(weather: weather) },
                    onSkip: { appState.skipWeatherCheckIn() }
                )
            } else {
                switch appState.currentScreen {
                case .dashboard:
                    DashboardView()
                case .nudge:
                    NudgeView()
                case .practice:
                    PracticeRouterView(practiceType: practiceType)
                case .weatherBefore:
                    WeatherPickerView(isBefore: true)
                case .weatherAfter:
                    WeatherPickerView(isBefore: false)
                case .completion:
                    CompletionView()
                case .whatHelped:
                    WhatHelpedView(practiceCategory: appState.lastPracticeCategory ?? .breathing)
                case .settings:
                    SettingsView()
                case .onboarding:
                    OnboardingView()
                case .summary:
                    DaySummaryView()
                case .playtest:
                    if let service = appState.playtestService {
                        PlaytestView(
                            service: service,
                            onBack: { appState.showSettings() },
                            onScenarioTap: { scenario in
                                appState.showPlaytestDetail(scenario)
                            }
                        )
                    }
                case .playtestDetail(let scenario):
                    if let service = appState.playtestService {
                        ScenarioDetailView(
                            scenario: scenario,
                            evaluation: service.evaluation(for: scenario.id),
                            onBack: { appState.showPlaytest() }
                        )
                    }
                case .practiceLibrary:
                    PracticeLibraryView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
        .onKeyPress(.escape) {
            if appState.currentScreen != .dashboard {
                appState.showDashboard()
                return .handled
            }
            return .ignored
        }
    }
}

#Preview {
    MainView()
        .environment(AppState())
        .frame(width: 360, height: 480)
}
