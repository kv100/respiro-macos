import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \StressEntry.timestamp) private var allEntries: [StressEntry]
    @State private var iconScale: CGFloat = 1.0
    @State private var silenceCardExpanded: Bool = false
    @State private var silenceCardVisible: Bool = false
    @State private var currentTip: WellnessTip?
    @State private var lastTipRefresh: Date = .distantPast
    @State private var now: Date = Date()  // live-updating clock for "X min ago"
    private let minuteTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var todayEntries: [StressEntry] {
        let start = Calendar.current.startOfDay(for: Date())
        return allEntries.filter { $0.timestamp >= start }
    }

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
                    StressGraphView(entries: todayEntries)
                    monitoringCard

                    // Behavioral metrics card (shows when behavioral data is available)
                    if appState.isMonitoring,
                       let metrics = appState.currentBehaviorMetrics,
                       let system = appState.currentSystemContext {
                        BehaviorMetricsCard(
                            behaviorMetrics: metrics,
                            systemContext: system,
                            baselineDeviation: appState.currentBaselineDeviation
                        )
                    }

                    if let silence = appState.lastSilenceDecision {
                        silenceDecisionCard(silence)
                            .opacity(silenceCardVisible ? 1 : 0)
                            .animation(.easeIn(duration: 0.4), value: silenceCardVisible)
                            .onChange(of: appState.lastSilenceDecision?.id) { _, _ in
                                silenceCardVisible = false
                                silenceCardExpanded = false
                                withAnimation(.easeIn(duration: 0.4)) {
                                    silenceCardVisible = true
                                }
                            }
                            .onAppear {
                                silenceCardVisible = true
                            }
                    }
                    if let tip = currentTip {
                        wellnessTipCard(tip)
                    }
                    practiceLibraryButton
                    daySummaryButton
                }
                .padding(16)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: .infinity)
            .task {
                refreshTip()
            }
            .onChange(of: appState.currentScreen) { _, newScreen in
                if newScreen == .dashboard {
                    refreshTip()
                }
            }
            .onReceive(minuteTimer) { _ in
                now = Date()
            }

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // ZONE C: Action Bar (56pt)
            actionBar
                .frame(height: 56)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#142823"))
    }

    // MARK: - Zone A: Status Header

    private var statusHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz")
                    .font(.system(size: 32))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(weatherAccentColor(appState.currentWeather))
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.bounce, value: appState.currentWeather)
                    .scaleEffect(iconScale)
                    .animation(.easeInOut(duration: 0.3), value: appState.currentWeather)
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

        }
        .padding(.top, 12)
    }

    private func weatherAccentColor(_ weather: InnerWeather) -> Color {
        switch weather {
        case .clear: return Color(hex: "#10B981")
        case .cloudy: return Color(hex: "#8BA4B0")
        case .stormy: return Color(hex: "#7B6B9E")
        }
    }

    // MARK: - Zone B: Content Cards

    private var monitoringCard: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isMonitoring ? Color(hex: "#10B981") : Color(hex: "#E0F4EE").opacity(0.30))
                .frame(width: 8, height: 8)

            if appState.isMonitoring, !appState.monitoringDiagnostic.isEmpty {
                Text(appState.monitoringDiagnostic)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.72))
            } else {
                Text("Paused")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }

            Spacer()
        }
        .padding(10)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Silence Decision Card

    private func silenceDecisionCard(_ decision: SilenceDecision) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                silenceCardExpanded.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "#10B981"))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chose not to interrupt")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                        Text(silenceCardExpanded ? decision.thinkingText : truncatedThinking(decision.thinkingText))
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                            .lineLimit(silenceCardExpanded ? nil : 2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                HStack {
                    EffortIndicatorView(level: decision.effortLevel)

                    Spacer()

                    Text(timeAgo(decision.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }
            }
            .padding(12)
            .background(Color(hex: "#C7E8DE").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func truncatedThinking(_ text: String) -> String {
        if text.count <= 80 { return text }
        let index = text.index(text.startIndex, offsetBy: 80)
        return String(text[..<index]) + "..."
    }

    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        if seconds < 60 { return "Just now" }
        let minutes = seconds / 60
        if minutes == 1 { return "1 min ago" }
        if minutes < 60 { return "\(minutes) min ago" }
        let hours = minutes / 60
        if hours == 1 { return "1 hr ago" }
        return "\(hours) hr ago"
    }

    // MARK: - Wellness Tip Card

    private func wellnessTipCard(_ tip: WellnessTip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#D4AF37"))

                Text(tip.category.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#D4AF37"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#D4AF37").opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()
            }

            Text(tip.text)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func refreshTip() {
        guard Date().timeIntervalSince(lastTipRefresh) > 1800 || currentTip == nil else { return }
        currentTip = TipService().tipFor(weather: appState.currentWeather)
        lastTipRefresh = Date()
    }

    // MARK: - Practice Library Button

    private var practiceLibraryButton: some View {
        Button(action: {
            appState.showPracticeLibrary()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "books.vertical")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#10B981"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Practice Library")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                    Text("Browse all 20 practices")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
            }
            .padding(12)
            .background(Color(hex: "#C7E8DE").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Summary Button

    private var daySummaryButton: some View {
        Button(action: {
            appState.showSummary()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "#D4AF37"))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Day Summary")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

                    Text("AI reflection on your day")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
            }
            .padding(12)
            .background(Color(hex: "#C7E8DE").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Zone C: Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            // Start Practice button
            Button(action: {
                // Smart practice selection based on current weather
                let practice = appState.pickPracticeForInternalStress()
                appState.selectedPracticeID = practice.id
                appState.showWeatherBefore()
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
