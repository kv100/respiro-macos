import SwiftUI

struct BreathingPracticeView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()
    @State private var glowRadius: CGFloat = 10

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                practiceHeader
                    .padding(.top, 8)

                Spacer()

                // Breathing circle
                breathingCircle

                // Phase label
                phaseLabel
                    .padding(.top, 20)

                Spacer()

                // Progress dots
                progressDots
                    .padding(.bottom, 16)

                // Timer
                timerLabel
                    .padding(.bottom, 12)

                // Controls
                controlButtons
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 420, height: 560)
        .onAppear {
            SoundService.shared.playPracticeStart()
            practiceManager.startPractice()
        }
        .onDisappear {
            practiceManager.stopPractice()
        }
        .onChange(of: practiceManager.isActive) { oldValue, newValue in
            if oldValue == true && newValue == false {
                appState.showWeatherAfter()
            }
        }
    }

    // MARK: - Header

    private var practiceHeader: some View {
        HStack {
            Button(action: {
                practiceManager.stopPractice()
                appState.showDashboard()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Physiological Sigh")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            // Balance the back button width
            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Breathing Circle

    private var breathingCircle: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#10B981").opacity(0.15),
                            Color(hex: "#10B981").opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            // Main breathing circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#10B981").opacity(0.8),
                            Color(hex: "#10B981").opacity(0.2)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .shadow(color: Color(hex: "#10B981").opacity(glowOpacityForPhase), radius: glowRadius)
                .scaleEffect(scaleForPhase)
                .opacity(opacityForPhase)
                .animation(animationForPhase, value: practiceManager.currentPhase)
                .animation(animationForPhase, value: practiceManager.phaseDuration)
        }
        .onChange(of: practiceManager.currentPhase) { _, newPhase in
            animateGlow(for: newPhase)
        }
    }

    private var scaleForPhase: CGFloat {
        switch practiceManager.currentPhase {
        case .idle: return 0.6
        case .inhale: return 1.0
        case .hold: return 1.0
        case .exhale: return 0.6
        }
    }

    private var opacityForPhase: Double {
        switch practiceManager.currentPhase {
        case .hold: return 0.9
        default: return 1.0
        }
    }

    private var glowOpacityForPhase: Double {
        switch practiceManager.currentPhase {
        case .inhale: return 0.5
        case .hold: return 0.35
        case .exhale: return 0.15
        case .idle: return 0.1
        }
    }

    private var animationForPhase: Animation {
        .easeInOut(duration: practiceManager.currentPhase == .idle ? 0.3 : practiceManager.phaseDuration)
    }

    private func animateGlow(for phase: BreathPhase) {
        let duration = practiceManager.phaseDuration
        switch phase {
        case .inhale:
            withAnimation(.easeInOut(duration: duration)) {
                glowRadius = 25
            }
        case .hold:
            withAnimation(.easeInOut(duration: duration)) {
                glowRadius = 20
            }
        case .exhale:
            withAnimation(.easeInOut(duration: duration)) {
                glowRadius = 8
            }
        case .idle:
            withAnimation(.easeInOut(duration: 0.3)) {
                glowRadius = 10
            }
        }
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        Text(practiceManager.currentPhase == .idle ? "" : practiceManager.currentPhase.label)
            .font(.system(size: 16, weight: .medium))
            .tracking(4)
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
            .animation(.easeInOut(duration: 0.2), value: practiceManager.currentPhase)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<practiceManager.totalCycles, id: \.self) { index in
                Circle()
                    .fill(index < practiceManager.completedCycles
                        ? Color(hex: "#10B981")
                        : Color(hex: "#C7E8DE").opacity(0.15))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: practiceManager.completedCycles)
            }
        }
    }

    // MARK: - Timer

    private var timerLabel: some View {
        Text("\(practiceManager.remainingFormatted) remaining")
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            .monospacedDigit()
    }

    // MARK: - Controls

    private var controlButtons: some View {
        HStack(spacing: 12) {
            if practiceManager.isActive {
                Button(action: {
                    if practiceManager.isPaused {
                        practiceManager.resumePractice()
                    } else {
                        practiceManager.pausePractice()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: practiceManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 13))
                        Text(practiceManager.isPaused ? "Resume" : "Pause")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#10B981"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
            } else {
                // Practice completed
                Button(action: {
                    appState.showWeatherAfter()
                }) {
                    Text("Done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    BreathingPracticeView()
        .environment(AppState())
}
