import SwiftUI

struct ThoughtDefusionView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    private let accentColor = Color(hex: "#7B6B9E")

    var body: some View {
        ZStack {
            Color(hex: "#0A1F1A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                defusionCard

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
            practiceManager.startPractice(type: .thoughtDefusion)
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

            Text("Thought Defusion")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Defusion Card

    private var defusionCard: some View {
        VStack(spacing: 20) {
            Image(systemName: iconForPhase)
                .font(.system(size: 40))
                .foregroundStyle(accentColor)
                .contentTransition(.symbolEffect(.replace))

            Text(practiceManager.currentDefusionPhase.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Text(practiceManager.currentDefusionPhase.instruction)
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
        .animation(.easeInOut(duration: 0.6), value: practiceManager.currentDefusionPhase.rawValue)
    }

    private var iconForPhase: String {
        switch practiceManager.currentDefusionPhase {
        case .nameThought: return "text.bubble"
        case .noticeThought: return "eye"
        case .watchItPass: return "cloud"
        }
    }

    // MARK: - Phase Indicator

    private var phaseIndicator: some View {
        let phases: [DefusionPhase] = [.nameThought, .noticeThought, .watchItPass]

        return HStack(spacing: 16) {
            ForEach(phases, id: \.rawValue) { phase in
                let isCurrent = practiceManager.currentDefusionPhase == phase
                let isPast = phaseIndex(phase) < phaseIndex(practiceManager.currentDefusionPhase)

                VStack(spacing: 4) {
                    Circle()
                        .fill(
                            isCurrent ? accentColor :
                            isPast ? accentColor.opacity(0.5) :
                            Color(hex: "#C7E8DE").opacity(0.15)
                        )
                        .frame(width: 10, height: 10)

                    Text(phase.shortLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(
                            isCurrent ? accentColor :
                            isPast ? accentColor.opacity(0.5) :
                            Color(hex: "#E0F4EE").opacity(0.30)
                        )
                }
                .animation(.easeInOut(duration: 0.3), value: practiceManager.currentDefusionPhase.rawValue)
            }
        }
    }

    private func phaseIndex(_ phase: DefusionPhase) -> Int {
        switch phase {
        case .nameThought: return 0
        case .noticeThought: return 1
        case .watchItPass: return 2
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
    ThoughtDefusionView()
        .environment(AppState())
}
