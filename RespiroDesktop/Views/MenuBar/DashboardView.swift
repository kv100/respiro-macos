import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // ZONE A: Status Header (80pt)
            statusHeader
                .frame(height: 80)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // ZONE B: Content (flexible)
            ScrollView {
                VStack(spacing: 12) {
                    weatherStatusCard
                    monitoringCard
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // ZONE C: Action Bar (56pt)
            actionBar
                .frame(height: 56)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
    }

    // MARK: - Zone A: Status Header

    private var statusHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(hex: "#10B981"))
                    .contentTransition(.symbolEffect(.replace))
                    .scaleEffect(iconScale)
                    .onChange(of: appState.currentWeather) { _, _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            iconScale = 1.15
                        }
                        withAnimation(.easeInOut(duration: 0.15).delay(0.15)) {
                            iconScale = 1.0
                        }
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.isMonitoring ? appState.currentWeather.displayName : "Paused")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                    Text(appState.isMonitoring ? "Monitoring active" : "Monitoring paused")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // Mini timeline: 12 hourly dots
            miniTimeline
                .padding(.horizontal, 16)
        }
        .padding(.top, 12)
    }

    private var miniTimeline: some View {
        HStack(spacing: 6) {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(timelineDotColor(for: index))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func timelineDotColor(for index: Int) -> Color {
        // Placeholder: last 3 dots show current weather color, rest are dim
        if index >= 9 && appState.isMonitoring {
            return weatherAccentColor(appState.currentWeather)
        }
        return Color(hex: "#C7E8DE").opacity(0.15)
    }

    private func weatherAccentColor(_ weather: InnerWeather) -> Color {
        switch weather {
        case .clear: return Color(hex: "#10B981")
        case .cloudy: return Color(hex: "#8BA4B0")
        case .stormy: return Color(hex: "#7B6B9E")
        }
    }

    // MARK: - Zone B: Content Cards

    private var weatherStatusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#10B981"))
                Text("Inner Weather")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
            }

            Text(weatherDescription)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var weatherDescription: String {
        guard appState.isMonitoring else {
            return "Start monitoring to track your inner weather throughout the day."
        }
        switch appState.currentWeather {
        case .clear:
            return "Skies are clear. You seem focused and calm."
        case .cloudy:
            return "Some clouds gathering. A small break might help."
        case .stormy:
            return "Stormy conditions detected. Consider a breathing practice."
        }
    }

    private var monitoringCard: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(appState.isMonitoring ? Color(hex: "#10B981") : Color(hex: "#E0F4EE").opacity(0.30))
                .frame(width: 8, height: 8)

            Text(appState.isMonitoring ? "Active — checking periodically" : "Paused — no screenshots being taken")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))

            Spacer()
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Zone C: Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Start Practice button
            Button(action: {
                appState.showPractice()
            }) {
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

            // Toggle monitoring
            Button(action: {
                Task { await appState.toggleMonitoring() }
            }) {
                Image(systemName: appState.isMonitoring ? "pause.fill" : "play.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#C7E8DE").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // Settings
            Button(action: {
                appState.showSettings()
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#C7E8DE").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
}
