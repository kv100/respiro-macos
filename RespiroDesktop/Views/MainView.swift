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
