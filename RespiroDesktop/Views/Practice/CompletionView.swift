import SwiftUI

struct CompletionView: View {
    @Environment(AppState.self) private var appState
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0

    private let scienceSnippets = [
        "Slow breathing activates your parasympathetic nervous system, lowering cortisol within minutes.",
        "Studies show that even 60 seconds of controlled breathing can reduce heart rate by 5-10 BPM.",
        "The vagus nerve responds to extended exhales, signaling your body to relax.",
        "Research from Stanford found that cyclic sighing is more effective than meditation for reducing anxiety.",
        "Breathing exercises can lower blood pressure for up to 24 hours after practice.",
        "Controlled breathing increases heart rate variability, a key marker of stress resilience.",
        "Just 5 minutes of breath work can shift your brain from beta waves to calming alpha waves.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark animation
            checkmarkBadge
                .padding(.bottom, 24)

            // Title
            Text("Practice Complete")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                .padding(.bottom, 16)

            // Delta badge
            if let before = appState.selectedWeatherBefore,
               let after = appState.selectedWeatherAfter {
                deltaBadge(before: before, after: after)
                    .padding(.bottom, 20)
            }

            // Science snippet
            Text(scienceSnippets.randomElement() ?? scienceSnippets[0])
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.70))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 32)

            Spacer()

            // Done button
            Button(action: {
                appState.selectedWeatherBefore = nil
                appState.selectedWeatherAfter = nil
                appState.showDashboard()
            }) {
                Text("Done")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#10B981"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .keyboardShortcut(.return, modifiers: [])
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
        }
    }

    // MARK: - Checkmark Badge

    private var checkmarkBadge: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#10B981").opacity(0.15))
                .frame(width: 96, height: 96)

            Circle()
                .fill(Color(hex: "#10B981").opacity(0.25))
                .frame(width: 72, height: 72)

            Image(systemName: "checkmark")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color(hex: "#10B981"))
        }
        .scaleEffect(checkmarkScale)
        .opacity(checkmarkOpacity)
    }

    // MARK: - Delta Badge

    private func deltaBadge(before: InnerWeather, after: InnerWeather) -> some View {
        HStack(spacing: 12) {
            weatherPill(before)

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

            weatherPill(after)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func weatherPill(_ weather: InnerWeather) -> some View {
        HStack(spacing: 6) {
            Image(systemName: weather.sfSymbol)
                .font(.system(size: 16))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(weatherColor(weather))

            Text(weather.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
        }
    }

    private func weatherColor(_ weather: InnerWeather) -> Color {
        switch weather {
        case .clear: return Color(hex: "#10B981")
        case .cloudy: return Color(hex: "#8BA4B0")
        case .stormy: return Color(hex: "#7B6B9E")
        }
    }
}

#Preview {
    let state = AppState()
    CompletionView()
        .environment(state)
        .onAppear {
            state.selectedWeatherBefore = .stormy
            state.selectedWeatherAfter = .clear
        }
}
