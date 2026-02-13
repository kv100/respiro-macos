import SwiftUI

/// Banner showing regression suite status
struct PlaytestRegressionBanner: View {
    let stillFailing: Int
    let fixed: Int
    let regression: Int
    let total: Int
    var onClearFixed: () -> Void
    var onRunRegression: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#EAB308"))

                Text("REGRESSION SUITE: \(total) scenarios")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Color.white.opacity(0.92))

                Spacer()
            }

            // Stats
            HStack(spacing: 12) {
                if fixed > 0 {
                    statBadge(
                        icon: "checkmark.circle.fill",
                        count: fixed,
                        label: "FIXED",
                        color: Color(hex: "#10B981")
                    )
                }

                if stillFailing > 0 {
                    statBadge(
                        icon: "exclamationmark.triangle.fill",
                        count: stillFailing,
                        label: "Still Failing",
                        color: Color(hex: "#EAB308")
                    )
                }

                if regression > 0 {
                    statBadge(
                        icon: "arrow.uturn.backward.circle.fill",
                        count: regression,
                        label: "Regressions",
                        color: Color(hex: "#EF4444")
                    )
                }

                Spacer()

                // Run regression suite button
                Button(action: onRunRegression) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 10))
                        Text("Run Suite")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#10B981").opacity(0.15))
                    )
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                // Clear fixed button
                if fixed > 0 {
                    Button(action: onClearFixed) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Clear Fixed")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                        )
                        .foregroundStyle(Color.white.opacity(0.72))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#EAB308").opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#EAB308").opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func statBadge(icon: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(color)
            Text("\(count) \(label)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.15))
        )
    }
}
