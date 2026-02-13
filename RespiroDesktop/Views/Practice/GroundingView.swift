import SwiftUI

struct GroundingView: View {
    @Environment(AppState.self) private var appState
    @State private var practiceManager = PracticeManager()

    private let accentColor = Color(hex: "#8BA4B0")

    var body: some View {
        ZStack {
            Color(hex: "#142823")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                practiceHeader
                    .padding(.top, 16)

                Spacer()

                senseDisplay

                Spacer()

                tapCircles
                    .padding(.bottom, 24)

                progressBar
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
            practiceManager.startPractice(type: .grounding)
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

            Text("5-4-3-2-1 Grounding")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()

            Color.clear.frame(width: 50)
        }
    }

    // MARK: - Sense Display

    private var senseDisplay: some View {
        VStack(spacing: 16) {
            Image(systemName: practiceManager.currentSense.icon)
                .font(.system(size: 48))
                .foregroundStyle(accentColor)
                .contentTransition(.symbolEffect(.replace))

            Text("\(practiceManager.currentSense.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)

            Text(practiceManager.currentSense.prompt)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .multilineTextAlignment(.center)
        }
        .animation(.easeInOut(duration: 0.4), value: practiceManager.currentSense.rawValue)
    }

    // MARK: - Tap Circles

    private var tapCircles: some View {
        HStack(spacing: 12) {
            let total = practiceManager.currentSense.count
            let done = practiceManager.currentSenseItemsDone

            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index < done ? accentColor : accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: done)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard practiceManager.isActive && !practiceManager.isPaused else { return }
            practiceManager.confirmGroundingItem()
        }
    }

    // MARK: - Progress

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#C7E8DE").opacity(0.10))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(accentColor)
                        .frame(
                            width: geo.size.width * CGFloat(practiceManager.completedGroundingItems) / CGFloat(practiceManager.totalGroundingItems),
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: practiceManager.completedGroundingItems)
                }
            }
            .frame(height: 6)

            Text("\(practiceManager.completedGroundingItems) of \(practiceManager.totalGroundingItems)")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
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
                    guard practiceManager.isActive && !practiceManager.isPaused else { return }
                    practiceManager.confirmGroundingItem()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 13))
                        Text("Tap to Confirm")
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
    GroundingView()
        .environment(AppState())
}
