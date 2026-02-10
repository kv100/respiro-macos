import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .dashboard:
                DashboardView()
            case .nudge:
                NudgeView()
            case .practice:
                BreathingPracticeView()
            case .weatherBefore:
                Text("Weather Before (P1.5)")
                    .foregroundStyle(.white)
            case .weatherAfter:
                Text("Weather After (P1.5)")
                    .foregroundStyle(.white)
            case .completion:
                Text("Completion View (P1.6)")
                    .foregroundStyle(.white)
            case .settings:
                Text("Settings View (P2.5)")
                    .foregroundStyle(.white)
            case .onboarding:
                Text("Onboarding View (P1.10)")
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    MainView()
        .environment(AppState())
        .frame(width: 360, height: 480)
}
