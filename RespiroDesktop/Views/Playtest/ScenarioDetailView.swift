import SwiftUI

struct ScenarioDetailView: View {
    let scenario: PlaytestScenario
    let evaluation: ScenarioEvaluation?
    var onBack: () -> Void

    @State private var showThinking = false
    @State private var showSuggestions = false

    // MARK: - Colors

    private let bgColor = Color(hex: "#142823")
    private let surfaceColor = Color(red: 199 / 255, green: 232 / 255, blue: 222 / 255).opacity(0.08)
    private let dividerColor = Color(hex: "#C0E0D6").opacity(0.10)
    private let jadePrimary = Color(hex: "#10B981")
    private let goldAccent = Color(hex: "#D4AF37")
    private let blueGray = Color(hex: "#8BA4B0")
    private let textPrimary = Color(hex: "#E0F4EE").opacity(0.92)
    private let textSecondary = Color(hex: "#E0F4EE").opacity(0.60)
    private let textTertiary = Color(hex: "#E0F4EE").opacity(0.45)

    var body: some View {
        VStack(spacing: 0) {
            detailHeader
            Divider().background(dividerColor)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if scenario.round > 1, let hypothesis = scenario.hypothesis {
                        hypothesisSection(hypothesis)
                    }
                    expectedActualSection
                    stepsSection
                    if let eval = evaluation {
                        analysisSection(eval)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.never)
        }
        .frame(width: 420, height: 560)
        .background(bgColor)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(jadePrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                statusBadge
            }

            HStack(spacing: 6) {
                Text("\(scenario.id.uppercased()): \(scenario.name)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(1)
            }

            if scenario.round > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 11))
                    Text("AI-Generated")
                        .font(.system(size: 11, weight: .medium))
                    Text("·")
                        .font(.system(size: 11))
                    Text("Round \(scenario.round)")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(blueGray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(blueGray.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let eval = evaluation {
            HStack(spacing: 4) {
                Image(systemName: eval.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text(eval.passed ? "PASSED" : "FAILED")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(eval.passed ? jadePrimary : goldAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((eval.passed ? jadePrimary : goldAccent).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text("PENDING")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(textTertiary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: - Hypothesis

    private func hypothesisSection(_ hypothesis: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("HYPOTHESIS")

            Text(hypothesis)
                .font(.system(size: 13).italic())
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Expected vs Actual

    private var expectedActualSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Expected
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("EXPECTED BEHAVIOR")

                ForEach(Array(scenario.expectedBehavior.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundStyle(textSecondary)
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundStyle(textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Divider().background(dividerColor)

            // Actual
            VStack(alignment: .leading, spacing: 6) {
                sectionHeader("ACTUAL BEHAVIOR")

                if let eval = evaluation {
                    if eval.mismatches.isEmpty {
                        // All passed — show all with green checkmarks
                        ForEach(Array(scenario.expectedBehavior.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\u{2705}")
                                    .font(.system(size: 12))
                                Text(item)
                                    .font(.system(size: 13))
                                    .foregroundStyle(jadePrimary.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        // Has mismatches — show expected with neutral style, then mismatches
                        ForEach(Array(scenario.expectedBehavior.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 6) {
                                Text(eval.passed ? "\u{2705}" : "\u{26A0}\u{FE0F}")
                                    .font(.system(size: 12))
                                Text(item)
                                    .font(.system(size: 13))
                                    .foregroundStyle(textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        ForEach(eval.mismatches, id: \.self) { mismatch in
                            HStack(alignment: .top, spacing: 6) {
                                Text("\u{274C}")
                                    .font(.system(size: 12))
                                Text(mismatch)
                                    .font(.system(size: 13))
                                    .foregroundStyle(goldAccent.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    Text("Awaiting evaluation...")
                        .font(.system(size: 13).italic())
                        .foregroundStyle(textTertiary)
                }
            }
        }
        .padding(12)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Steps Trace

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("STEPS")

            ForEach(scenario.steps) { step in
                stepRow(step)
            }
        }
        .padding(12)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func stepRow(_ step: ScenarioStep) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text("Step \(step.id)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(jadePrimary)
                Text(": \(step.description)")
                    .font(.system(size: 12))
                    .foregroundStyle(textPrimary)
                    .lineLimit(2)
            }

            HStack(spacing: 12) {
                let hasNudge = step.mockAnalysis.nudgeType != nil
                HStack(spacing: 4) {
                    Text("Nudge:")
                        .font(.system(size: 11))
                        .foregroundStyle(textTertiary)
                    Text(hasNudge ? "Yes (\(step.mockAnalysis.nudgeType ?? ""))" : "No")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(hasNudge ? jadePrimary : textSecondary)
                }

                HStack(spacing: 4) {
                    Text("Weather:")
                        .font(.system(size: 11))
                        .foregroundStyle(textTertiary)
                    Text(step.mockAnalysis.weather.capitalized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(weatherColor(step.mockAnalysis.weather))
                }
            }

            if let action = step.userAction {
                HStack(spacing: 4) {
                    Text("Action:")
                        .font(.system(size: 11))
                        .foregroundStyle(textTertiary)
                    Text(actionLabel(action))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(blueGray)
                }
            }

            if step.timeDelta > 0 {
                Text("+\(Int(step.timeDelta / 60))min")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(textTertiary)
            }

            // Behavioral context
            if let metrics = step.behaviorMetrics {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Behavioral Context")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(textTertiary)

                    HStack(spacing: 16) {
                        MetricBadge(
                            icon: "arrow.triangle.2.circlepath",
                            label: "Switches",
                            value: String(format: "%.1f/min", metrics.contextSwitchesPerMinute),
                            color: switchColor(metrics.contextSwitchesPerMinute)
                        )

                        MetricBadge(
                            icon: "clock",
                            label: "Session",
                            value: "\(Int(metrics.sessionDuration / 60))m",
                            color: durationColor(metrics.sessionDuration)
                        )

                        MetricBadge(
                            icon: "chart.pie",
                            label: "Focus",
                            value: "\(Int((metrics.applicationFocus.values.max() ?? 0) * 100))%",
                            color: focusColor(metrics.applicationFocus)
                        )
                    }
                }
                .padding(.top, 8)
            }

            if let deviation = step.baselineDeviation {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 10))
                    Text("Baseline: +\(Int(deviation * 100))% above normal")
                        .font(.system(size: 10))
                }
                .foregroundStyle(deviationColor(deviation))
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            if step.id != scenario.steps.last?.id {
                Divider().background(dividerColor)
            }
        }
    }

    // MARK: - AI Analysis

    private func analysisSection(_ eval: ScenarioEvaluation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundStyle(jadePrimary)
                Text("AI Analysis")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textPrimary)
            }

            Text(eval.reasoning)
                .font(.system(size: 12))
                .foregroundStyle(textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Confidence
            HStack(spacing: 6) {
                Text("Confidence:")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textTertiary)
                Text("\(Int(eval.confidence * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(confidenceColor(eval.confidence))
            }

            // Behavioral context usage
            if eval.usedBehavioralContext {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("Used Behavioral Context")
                        .font(.system(size: 11))
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(hex: "#EF4444"))
                    Text("Ignored Behavioral Context")
                        .font(.system(size: 11))
                }
            }

            if let quality = eval.behavioralReasoningQuality {
                HStack(spacing: 4) {
                    Text("Behavioral Reasoning Quality:")
                        .font(.system(size: 11))
                        .foregroundStyle(textTertiary)
                    Text("\(Int(quality * 100))%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(qualityColor(quality))
                }
            }

            // Mismatches
            if !eval.mismatches.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mismatches:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(goldAccent)

                    ForEach(eval.mismatches, id: \.self) { mismatch in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .font(.system(size: 12))
                            Text(mismatch)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(goldAccent.opacity(0.85))
                    }
                }
            }

            // Suggestions
            if !eval.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSuggestions.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showSuggestions ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Suggestions (\(eval.suggestions.count))")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(blueGray)
                    }
                    .buttonStyle(.plain)

                    if showSuggestions {
                        ForEach(eval.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                    .font(.system(size: 12))
                                Text(suggestion)
                                    .font(.system(size: 12))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(blueGray.opacity(0.85))
                        }
                    }
                }
            }

            // Full Thinking
            if let thinking = eval.thinkingText, !thinking.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showThinking.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showThinking ? "chevron.down" : "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                            Text("View Full Thinking")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(jadePrimary.opacity(0.8))
                    }
                    .buttonStyle(.plain)

                    if showThinking {
                        Text(thinking)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
        .padding(12)
        .background(surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(textTertiary)
            .tracking(0.8)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.80 { return jadePrimary }
        if confidence >= 0.60 { return blueGray }
        return goldAccent
    }

    private func qualityColor(_ quality: Double) -> Color {
        if quality > 0.7 { return Color(hex: "#10B981") }
        if quality > 0.4 { return Color(hex: "#EAB308") }
        return Color(hex: "#EF4444")
    }

    private func weatherColor(_ weather: String) -> Color {
        switch weather.lowercased() {
        case "clear": return jadePrimary
        case "cloudy": return blueGray
        case "stormy": return goldAccent
        default: return textSecondary
        }
    }

    private func actionLabel(_ action: PlaytestUserAction) -> String {
        switch action {
        case .dismissImFine: return "Dismiss (I'm Fine)"
        case .dismissLater: return "Dismiss (Later)"
        case .startPractice: return "Start Practice"
        case .completePractice: return "Complete Practice"
        }
    }

    // MARK: - Behavioral Metrics Color Helpers

    private func switchColor(_ rate: Double) -> Color {
        if rate < 2.0 { return Color(hex: "#10B981") }
        if rate < 5.0 { return Color(hex: "#EAB308") }
        return Color(hex: "#A855F7")
    }

    private func durationColor(_ duration: TimeInterval) -> Color {
        if duration < 3600 { return Color(hex: "#10B981") }
        if duration < 7200 { return Color(hex: "#EAB308") }
        return Color(hex: "#A855F7")
    }

    private func focusColor(_ focus: [String: Double]) -> Color {
        let max = focus.values.max() ?? 0
        if max > 0.7 { return Color(hex: "#10B981") }
        if max > 0.4 { return Color(hex: "#EAB308") }
        return Color(hex: "#A855F7")
    }

    private func deviationColor(_ deviation: Double) -> Color {
        if deviation < 0.5 { return Color(hex: "#10B981") }
        if deviation < 1.5 { return Color(hex: "#EAB308") }
        return Color(hex: "#A855F7")
    }
}

// MARK: - MetricBadge Helper View

struct MetricBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
