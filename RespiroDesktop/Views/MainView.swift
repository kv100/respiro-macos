import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedPracticeType: PracticeType = .physiologicalSigh

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
                    PracticeRouterView(practiceType: selectedPracticeType)
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
    }
}

#Preview {
    MainView()
        .environment(AppState())
        .frame(width: 360, height: 480)
}
