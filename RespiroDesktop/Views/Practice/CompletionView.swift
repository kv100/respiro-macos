import SwiftUI

struct CompletionView: View {
    @Environment(AppState.self) private var appState
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    @State private var sparklePhase: Int = 0
    @State private var deltaBadgeOffset: CGFloat = 10
    @State private var deltaBadgeOpacity: Double = 0

    private func scienceSnippet(for category: PracticeCategory) -> String {
        let snippets: [String]
        switch category {
        case .breathing:
            snippets = [
                "Slow breathing activates your parasympathetic nervous system, lowering cortisol within minutes.",
                "Studies show that even 60 seconds of controlled breathing can reduce heart rate by 5-10 BPM.",
                "The vagus nerve responds to extended exhales, signaling your body to relax.",
                "Research from Stanford found that cyclic sighing is more effective than meditation for reducing anxiety.",
                "Controlled breathing increases heart rate variability, a key marker of stress resilience.",
                "Just 5 minutes of breath work can shift your brain from beta waves to calming alpha waves.",
                "Breathing at 6 breaths per minute optimizes heart-lung coupling for maximum calm.",
                "4-7-8 breathing was designed by Dr. Andrew Weil as a 'natural tranquilizer' for the nervous system.",
            ]
        case .body:
            snippets = [
                "Progressive muscle relaxation reduces tension headaches by up to 50% in clinical studies.",
                "Body scan meditation activates the insula cortex, improving awareness of physical stress signals.",
                "Gentle stretching releases fascia tension and increases blood flow to tight muscles.",
                "Grounding techniques engage the somatosensory cortex, pulling focus from anxious thoughts to physical sensation.",
                "Physical micro-breaks every 30 minutes reduce musculoskeletal strain by 40%.",
                "Standing and stretching for just 60 seconds can reduce cortisol and boost alertness.",
            ]
        case .mind:
            snippets = [
                "Cognitive defusion techniques reduce the believability of negative thoughts by 30-40%.",
                "Self-compassion practices lower inflammation markers (IL-6) after just 3 weeks of regular use.",
                "The STOP technique interrupts the stress-response loop before it escalates to fight-or-flight.",
                "Loving-kindness meditation increases positive emotions and social connectedness within 7 days.",
                "Naming emotions ('affect labeling') reduces amygdala reactivity by up to 43%.",
                "Visualization activates similar neural pathways as the real experience, priming calm responses.",
                "Worry containment ('worry time') reduces generalized anxiety symptoms by limiting rumination.",
            ]
        }
        return snippets.randomElement() ?? snippets[0]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Checkmark animation with sparkles
            ZStack {
                sparkleEffect
                checkmarkBadge
            }
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
                    .offset(y: deltaBadgeOffset)
                    .opacity(deltaBadgeOpacity)
            }

            // Science snippet
            Text(scienceSnippet(for: appState.lastPracticeCategory ?? .breathing))
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.70))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 32)

            Spacer()

            // Done button
            Button(action: {
                appState.completedPracticeCount += 1
                if appState.completedPracticeCount >= 3 {
                    appState.showWhatHelped()
                } else {
                    appState.selectedWeatherBefore = nil
                    appState.selectedWeatherAfter = nil
                    appState.showDashboard()
                }
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
        .background(Color(hex: "#142823"))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                checkmarkScale = 1.0
                checkmarkOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                deltaBadgeOffset = 0
                deltaBadgeOpacity = 1.0
            }
            // Trigger sparkle cycle
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 400_000_000)
                withAnimation(.easeInOut(duration: 0.6)) {
                    sparklePhase = 1
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                withAnimation(.easeInOut(duration: 0.8)) {
                    sparklePhase = 2
                }
            }
        }
    }

    // MARK: - Sparkle Effect

    private var sparkleEffect: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                let angle = Double(index) * 60.0
                let radians = angle * .pi / 180.0
                let radius: CGFloat = sparklePhase >= 1 ? 56 : 20
                Image(systemName: "sparkle")
                    .font(.system(size: sparklePhase >= 2 ? 8 : 10))
                    .foregroundStyle(Color(hex: "#10B981").opacity(sparklePhase >= 1 ? 0.7 : 0))
                    .offset(
                        x: cos(radians) * radius,
                        y: sin(radians) * radius
                    )
                    .scaleEffect(sparklePhase >= 2 ? 0.3 : 1.0)
                    .opacity(sparklePhase >= 2 ? 0 : 1)
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
        .shadow(color: Color(hex: "#10B981").opacity(0.3), radius: 15)
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
