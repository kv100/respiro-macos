import SwiftUI

struct SelfCompassionView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    private let accentColor = Color(hex: "#D4AF37")

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                compassionCard

                Spacer()

                phaseIndicator
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
            practiceManager.startPractice(type: .selfCompassion)
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

            Text("Self-Compassion")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Compassion Card

    private var compassionCard: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: iconForPhase)
                .font(.system(size: 40))
                .foregroundStyle(accentColor)
                .contentTransition(.symbolEffect(.replace))

            // Title
            Text(practiceManager.currentCompassionPhase.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            // Instruction
            Text(practiceManager.currentCompassionPhase.instruction)
                .font(.system(size: 15))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.6), value: practiceManager.currentCompassionPhase.rawValue)
    }

    private var iconForPhase: String {
        switch practiceManager.currentCompassionPhase {
        case .mindfulness: return "brain.head.profile"
        case .commonHumanity: return "person.2"
        case .kindness: return "heart"
        }
    }

    // MARK: - Phase Indicator

    private var phaseIndicator: some View {
        let phases: [CompassionPhase] = [.mindfulness, .commonHumanity, .kindness]

        return HStack(spacing: 16) {
            ForEach(phases, id: \.rawValue) { phase in
                let isCurrent = practiceManager.currentCompassionPhase == phase
                let isPast = phaseIndex(phase) < phaseIndex(practiceManager.currentCompassionPhase)

                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            isCurrent ? accentColor :
                            isPast ? accentColor.opacity(0.5) :
                            Color(hex: "#C7E8DE").opacity(0.15)
                        )
                        .frame(width: 10, height: 10)

                    Text(phase.title)
                        .font(.system(size: 10))
                        .foregroundStyle(
                            isCurrent ? accentColor :
                            isPast ? accentColor.opacity(0.5) :
                            Color(hex: "#E0F4EE").opacity(0.30)
                        )
                }
                .animation(.easeInOut(duration: 0.3), value: practiceManager.currentCompassionPhase.rawValue)
            }
        }
    }

    private func phaseIndex(_ phase: CompassionPhase) -> Int {
        switch phase {
        case .mindfulness: return 0
        case .commonHumanity: return 1
        case .kindness: return 2
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
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
            } else {
                Button(action: {
                    appState.showDashboard()
                }) {
                    Text("Done")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    SelfCompassionView()
        .environment(AppState())
}
