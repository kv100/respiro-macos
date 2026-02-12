import SwiftUI

struct PlaytestWindowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let service = appState.playtestService {
                PlaytestView(
                    service: service,
                    onBack: {
                        dismiss()
                    },
                    onScenarioTap: { scenario in
                        appState.showPlaytestDetail(scenario)
                    }
                )
            } else {
                // Fallback if service not configured
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: "#D4AF37"))

                    Text("Playtest service not configured")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .frame(width: 360, height: 480)
                .background(Color(hex: "#142823"))
            }
        }
    }
}
