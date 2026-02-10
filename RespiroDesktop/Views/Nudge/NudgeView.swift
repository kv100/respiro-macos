import SwiftUI

struct NudgeView: View {
    @Environment(AppState.self) private var appState
    @State private var isVisible = false
    @State private var autoDismissTask: Task<Void, Never>?

    // MARK: - Fallback Messages

    private static let encouragementMessages = [
        "Nice focus streak! You've been in the zone for a while.",
        "Smooth sailing — your work rhythm looks great today.",
        "Heads up: you've been at it for a while. Still feeling good?",
    ]

    private static let acknowledgmentMessages = [
        "Weather's clearing up — nice recovery.",
        "Looking calmer now. Whatever you did, it worked.",
        "The storm seems to be passing. Good job riding it out.",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if let nudge = appState.pendingNudge, nudge.shouldShow, let nudgeType = nudge.nudgeType {
                nudgeCard(nudge: nudge, type: nudgeType)
                    .padding(16)
                    .offset(y: isVisible ? 0 : 8)
                    .opacity(isVisible ? 1 : 0)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer()
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = true
            }
            scheduleAutoDismiss()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    // MARK: - Nudge Card

    @ViewBuilder
    private func nudgeCard(nudge: NudgeDecision, type: NudgeType) -> some View {
        HStack(spacing: 0) {
            // Left accent border
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor(for: type))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 12) {
                // Header: icon + type label
                HStack(spacing: 8) {
                    Image(systemName: iconName(for: type))
                        .font(.system(size: 16))
                        .foregroundStyle(accentColor(for: type))

                    Text(headerText(for: type))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                    Spacer()

                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
                    }
                    .buttonStyle(.plain)
                }

                // AI message or fallback
                Text(displayMessage(for: nudge, type: type))
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Action buttons based on nudge type
                actionButtons(for: type)
            }
            .padding(12)
        }
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Message Resolution

    private func displayMessage(for nudge: NudgeDecision, type: NudgeType) -> String {
        if let message = nudge.message, !message.isEmpty {
            return message
        }
        // Fallback to random message based on type
        switch type {
        case .encouragement:
            return Self.encouragementMessages.randomElement() ?? Self.encouragementMessages[0]
        case .acknowledgment:
            return Self.acknowledgmentMessages.randomElement() ?? Self.acknowledgmentMessages[0]
        case .practice:
            return "A quick practice might help you feel more centered."
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(for type: NudgeType) -> some View {
        switch type {
        case .practice:
            practiceButtons
        case .encouragement:
            encouragementButtons
        case .acknowledgment:
            EmptyView()
        }
    }

    private var practiceButtons: some View {
        VStack(spacing: 8) {
            // Start Practice -- primary action
            Button {
                autoDismissTask?.cancel()
                appState.showPractice()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 13))
                    Text("Start Practice")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#10B981"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                // I'm Fine
                Button {
                    dismissWithFeedback()
                } label: {
                    Text("I'm Fine")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.70))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#C7E8DE").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                // Later
                Button {
                    dismissWithFeedback()
                } label: {
                    Text("Later")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.70))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#C7E8DE").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var encouragementButtons: some View {
        Button {
            dismiss()
        } label: {
            Text("Got it")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.70))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: "#C7E8DE").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling Helpers

    private func accentColor(for type: NudgeType) -> Color {
        switch type {
        case .practice: Color(hex: "#10B981")     // Gentle Nudge -- jade
        case .encouragement: Color(hex: "#8BA4B0") // Reassuring -- blue-gray
        case .acknowledgment: Color(hex: "#D4AF37") // Celebration -- gold
        }
    }

    private func iconName(for type: NudgeType) -> String {
        switch type {
        case .practice: "drop.fill"
        case .encouragement: "cloud.fill"
        case .acknowledgment: "trophy.fill"
        }
    }

    private func headerText(for type: NudgeType) -> String {
        switch type {
        case .practice: "Gentle Nudge"
        case .encouragement: "A Moment of Calm"
        case .acknowledgment: "Weather Clearing Up"
        }
    }

    // MARK: - Auto-dismiss

    private func scheduleAutoDismiss() {
        guard let nudge = appState.pendingNudge,
              let nudgeType = nudge.nudgeType else { return }

        let delay: UInt64 = switch nudgeType {
        case .practice: 30_000_000_000      // 30s
        case .encouragement: 10_000_000_000 // 10s
        case .acknowledgment: 5_000_000_000 // 5s
        }

        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }

    // MARK: - Actions

    private func dismiss() {
        autoDismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = false
        }
        // Small delay for animation to complete
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            appState.pendingNudge = nil
            appState.showDashboard()
        }
    }

    private func dismissWithFeedback() {
        autoDismissTask?.cancel()
        Task { @MainActor in
            await appState.notifyDismissal()
        }
        withAnimation(.easeIn(duration: 0.2)) {
            isVisible = false
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            appState.pendingNudge = nil
            appState.showDashboard()
        }
    }
}

#Preview("Practice Nudge") {
    let state = AppState()
    state.pendingNudge = NudgeDecision(
        shouldShow: true,
        nudgeType: .practice,
        message: "You seem to have a lot going on. A quick breathing exercise might help you refocus.",
        suggestedPracticeID: "physiological-sigh",
        reason: "approved"
    )
    return NudgeView()
        .environment(state)
}

#Preview("Encouragement") {
    let state = AppState()
    state.pendingNudge = NudgeDecision(
        shouldShow: true,
        nudgeType: .encouragement,
        message: nil,
        suggestedPracticeID: nil,
        reason: "approved"
    )
    return NudgeView()
        .environment(state)
}

#Preview("Acknowledgment") {
    let state = AppState()
    state.pendingNudge = NudgeDecision(
        shouldShow: true,
        nudgeType: .acknowledgment,
        message: nil,
        suggestedPracticeID: nil,
        reason: "approved"
    )
    return NudgeView()
        .environment(state)
}
