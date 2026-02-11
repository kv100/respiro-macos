import SwiftUI

struct STOPTechniqueView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    private let accentColor = Color(hex: "#7B6B9E")

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                phaseCard

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
            SoundService.shared.playPracticeStart()
            practiceManager.startPractice(type: .stopTechnique)
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

            Text("STOP Technique")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Phase Card

    private var phaseCard: some View {
        VStack(spacing: 20) {
            // Large letter
            Text(practiceManager.currentSTOPPhase.rawValue)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            // Title
            Text(practiceManager.currentSTOPPhase.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            // Instruction
            Text(practiceManager.currentSTOPPhase.instruction)
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
        .animation(.easeInOut(duration: 0.5), value: practiceManager.currentSTOPPhase.rawValue)
    }

    // MARK: - Phase Indicator

    private var phaseIndicator: some View {
        let phases: [STOPPhase] = [.stop, .takeABreath, .observe, .proceed]

        return HStack(spacing: 12) {
            ForEach(phases, id: \.rawValue) { phase in
                let isCurrent = practiceManager.currentSTOPPhase == phase
                let isPast = phaseIndex(phase) < phaseIndex(practiceManager.currentSTOPPhase)

                Text(phase.rawValue)
                    .font(.system(size: 16, weight: isCurrent ? .bold : .medium))
                    .foregroundStyle(
                        isCurrent ? accentColor :
                        isPast ? accentColor.opacity(0.5) :
                        Color(hex: "#E0F4EE").opacity(0.30)
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        isCurrent ? accentColor.opacity(0.15) :
                        isPast ? accentColor.opacity(0.05) :
                        Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .animation(.easeInOut(duration: 0.3), value: practiceManager.currentSTOPPhase.rawValue)
            }
        }
    }

    private func phaseIndex(_ phase: STOPPhase) -> Int {
        switch phase {
        case .stop: return 0
        case .takeABreath: return 1
        case .observe: return 2
        case .proceed: return 3
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
                    SoundService.shared.playPracticeComplete()
                    appState.showWeatherAfter()
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
    STOPTechniqueView()
        .environment(AppState())
}
