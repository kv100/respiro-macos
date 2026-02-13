import SwiftUI

struct BehaviorMetricsCard: View {
    let behaviorMetrics: BehaviorMetrics?
    let systemContext: SystemContext?
    let baselineDeviation: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Context")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

            if let behavior = behaviorMetrics, systemContext != nil {
                HStack(spacing: 16) {
                    MetricItem(
                        icon: "arrow.triangle.2.circlepath",
                        label: "Switches",
                        value: String(format: "%.1f/min", behavior.contextSwitchesPerMinute),
                        color: switchColor(behavior.contextSwitchesPerMinute)
                    )

                    MetricItem(
                        icon: "clock",
                        label: "Session",
                        value: formatDuration(behavior.sessionDuration),
                        color: durationColor(behavior.sessionDuration)
                    )

                    MetricItem(
                        icon: "chart.pie",
                        label: "Focus",
                        value: formatFocus(behavior.applicationFocus),
                        color: focusColor(behavior.applicationFocus)
                    )
                }

                if let deviation = baselineDeviation, deviation > 0.3 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 10))
                        Text("Baseline: +\(Int(deviation * 100))% above normal")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(deviationColor(deviation))
                    .padding(.top, 4)
                }
            } else {
                Text("No behavioral data available")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func switchColor(_ rate: Double) -> Color {
        if rate < 2.0 { return Color(hex: "#10B981") }  // jade green
        if rate < 5.0 { return Color(hex: "#D4AF37") }  // gold
        return Color(hex: "#7B6B9E")  // muted purple (stormy)
    }

    private func durationColor(_ duration: TimeInterval) -> Color {
        if duration < 3600 { return Color(hex: "#10B981") }  // < 1hr = good
        if duration < 7200 { return Color(hex: "#D4AF37") }  // 1-2hr = warning
        return Color(hex: "#7B6B9E")  // > 2hr = concern
    }

    private func focusColor(_ focus: [String: Double]) -> Color {
        let maxFocus = focus.values.max() ?? 0
        if maxFocus > 0.7 { return Color(hex: "#10B981") }  // focused
        if maxFocus > 0.4 { return Color(hex: "#D4AF37") }  // fragmented
        return Color(hex: "#7B6B9E")  // scattered
    }

    private func deviationColor(_ deviation: Double) -> Color {
        if deviation < 0.5 { return Color(hex: "#10B981") }
        if deviation < 1.5 { return Color(hex: "#D4AF37") }
        return Color(hex: "#7B6B9E")
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 { return "\(hours)h\(minutes)m" }
        return "\(minutes)m"
    }

    private func formatFocus(_ focus: [String: Double]) -> String {
        guard let max = focus.values.max() else { return "0%" }
        return "\(Int(max * 100))%"
    }
}

struct MetricItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// Preview
#Preview {
    BehaviorMetricsCard(
        behaviorMetrics: BehaviorMetrics(
            contextSwitchesPerMinute: 3.5,
            sessionDuration: 5400,
            applicationFocus: ["Xcode": 0.6, "Safari": 0.3, "Slack": 0.1],
            notificationAccumulation: 8,
            recentAppSequence: ["Xcode", "Safari", "Xcode", "Slack", "Xcode"]
        ),
        systemContext: SystemContext(
            activeApp: "Xcode",
            activeWindowTitle: nil,
            openWindowCount: 12,
            recentAppSwitches: ["Xcode", "Safari"],
            pendingNotificationCount: 0,
            isOnVideoCall: false,
            systemUptime: 7200,
            idleTime: 0
        ),
        baselineDeviation: 0.8
    )
    .frame(width: 328)
    .padding()
    .background(Color(hex: "#142823"))
}
