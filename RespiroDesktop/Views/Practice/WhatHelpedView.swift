import SwiftUI

struct WhatHelpedView: View {
    @Environment(AppState.self) private var appState
    let practiceCategory: PracticeCategory

    @State private var selectedOptions: Set<String> = []

    private var options: [String] {
        switch practiceCategory {
        case .breathing:
            return ["The rhythm", "Slowing down", "Focus on breath", "The pause"]
        case .body:
            return ["Noticing senses", "Being present", "Physical awareness", "Stepping back"]
        case .mind:
            return ["New perspective", "Self-kindness", "Letting go", "The structure"]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.bottom, 20)

            Text("What helped most?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                .padding(.bottom, 8)

            Text("Select 1-2 options")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                .padding(.bottom, 24)

            // Option chips
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    optionChip(option)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Buttons
            VStack(spacing: 10) {
                Button(action: {
                    appState.lastWhatHelped = Array(selectedOptions)
                    appState.completedPracticeCount = 0
                    appState.showDashboard()
                }) {
                    Text("Done")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedOptions.isEmpty
                            ? Color(hex: "#10B981").opacity(0.4)
                            : Color(hex: "#10B981"))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(selectedOptions.isEmpty)
                .keyboardShortcut(.return, modifiers: [])

                Button(action: {
                    appState.lastWhatHelped = nil
                    appState.completedPracticeCount = 0
                    appState.showDashboard()
                }) {
                    Text("Skip")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .frame(width: 420, height: 560)
        .background(Color(hex: "#142823"))
    }

    // MARK: - Option Chip

    private func optionChip(_ option: String) -> some View {
        let isSelected = selectedOptions.contains(option)

        return Button(action: {
            if isSelected {
                selectedOptions.remove(option)
            } else if selectedOptions.count < 2 {
                selectedOptions.insert(option)
            }
        }) {
            HStack {
                Text(option)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? Color(hex: "#E0F4EE").opacity(0.92)
                            : Color(hex: "#E0F4EE").opacity(0.70)
                    )

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Color(hex: "#10B981").opacity(0.08)
                    : Color(hex: "#C7E8DE").opacity(0.08)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? Color(hex: "#10B981").opacity(0.6)
                            : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    WhatHelpedView(practiceCategory: .breathing)
        .environment(AppState())
}
