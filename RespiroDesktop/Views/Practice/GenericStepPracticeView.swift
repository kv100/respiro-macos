import SwiftUI

struct GenericStepPracticeView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    let practiceType: PracticeType
    let practice: Practice

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                stepIndicator

                instructionText
                    .padding(.top, 24)

                Spacer()

                stepDots
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

            Text(practice.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        let stepIndex = practiceManager.currentGenericStep
        let totalSteps = practice.steps.count

        return ZStack {
            Circle()
                .fill(Color(hex: "#10B981").opacity(0.15))
                .frame(width: 120, height: 120)

            Circle()
                .fill(Color(hex: "#10B981").opacity(0.25))
                .frame(width: 90, height: 90)

            Text("\(stepIndex + 1)/\(totalSteps)")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color(hex: "#10B981"))
                .monospacedDigit()
        }
        .shadow(color: Color(hex: "#10B981").opacity(0.2), radius: 12)
        .animation(.easeInOut(duration: 0.3), value: stepIndex)
    }

    // MARK: - Instruction Text

    private var instructionText: some View {
        Text(practiceManager.currentStepInstruction.isEmpty
            ? (practice.steps.first?.instruction ?? "")
            : practiceManager.currentStepInstruction)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .frame(minHeight: 60)
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.3), value: practiceManager.currentGenericStep)
    }

    // MARK: - Step Dots

    private var stepDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<practice.steps.count, id: \.self) { index in
                Circle()
                    .fill(index <= practiceManager.currentGenericStep
                        ? Color(hex: "#10B981")
                        : Color(hex: "#C7E8DE").opacity(0.15))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: practiceManager.currentGenericStep)
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
    GenericStepPracticeView(
        practiceType: .bodyScan,
        practice: PracticeCatalog.bodyScan
    )
    .environment(AppState())
}
