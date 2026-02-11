import SwiftUI

struct GenericBreathingView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    let practiceType: PracticeType
    let title: String

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                breathingCircle

                phaseLabel
                    .padding(.top, 20)

                Spacer()

                progressDots
                    .padding(.bottom, 16)

                timerLabel
                    .padding(.bottom, 12)

                controlButtons
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 360, height: 480)
        .onAppear {
            SoundService.shared.playPracticeStart()
            practiceManager.startPractice(type: practiceType)
        }
        .onDisappear {
            practiceManager.stopPractice()
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

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Breathing Circle

    private var breathingCircle: some View {
        ZStack {
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
                .scaleEffect(scaleForPhase)
                .opacity(opacityForPhase)
                .animation(animationForPhase, value: practiceManager.currentPhase)
                .animation(animationForPhase, value: practiceManager.phaseDuration)
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

    private var animationForPhase: Animation {
        switch practiceManager.currentPhase {
        case .idle: return .easeInOut(duration: 0.3)
        default: return .easeInOut(duration: practiceManager.phaseDuration)
        }
    }

    // MARK: - Phase Label

    private var phaseLabel: some View {
        VStack(spacing: 6) {
            Text(practiceManager.currentPhase == .idle ? "" : practiceManager.currentPhase.label)
                .font(.system(size: 16, weight: .medium))
                .tracking(4)
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .animation(.easeInOut(duration: 0.2), value: practiceManager.currentPhase)

            if !practiceManager.currentStepInstruction.isEmpty
                && practiceType == .alternateNostril {
                Text(practiceManager.currentStepInstruction)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                    .animation(.easeInOut(duration: 0.2), value: practiceManager.currentStepInstruction)
            }
        }
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
                Button(action: {
                    SoundService.shared.playPracticeComplete()
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
    GenericBreathingView(practiceType: .fourSevenEight, title: "4-7-8 Breathing")
        .environment(AppState())
}
