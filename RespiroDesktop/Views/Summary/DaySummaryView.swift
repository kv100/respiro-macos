import SwiftUI
import SwiftData

struct DaySummaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var summary: DaySummaryResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .frame(height: 56)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // Content
            ScrollView {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if let summary {
                    summaryContent(summary)
                } else {
                    emptyView
                }
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // Close button
            closeBar
                .frame(height: 56)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#0A1F1A"))
        .task {
            await loadSummary()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "#D4AF37"))

            Text("Day Summary")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .controlSize(.regular)
                .tint(Color(hex: "#10B981"))

            Text("Reflecting on your day...")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(16)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: "#8BA4B0"))

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await loadSummary() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color(hex: "#10B981"))
        }
        .padding(24)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: "#8BA4B0"))

            Text("No data yet today. Start monitoring to collect stress readings.")
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }

    // MARK: - Summary Content

    private func summaryContent(_ summary: DaySummaryResponse) -> some View {
        VStack(spacing: 12) {
            // Day score ring
            dayScoreView(summary.dayScore)

            // Stress timeline
            stressTimeline

            // AI reflection cards
            reflectionCard(
                icon: "cloud.sun",
                title: "Overall Mood",
                text: summary.overallMood,
                accentColor: Color(hex: "#10B981")
            )

            reflectionCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Stress Pattern",
                text: summary.stressPattern,
                accentColor: Color(hex: "#7B6B9E")
            )

            reflectionCard(
                icon: "lungs.fill",
                title: "Most Effective Practice",
                text: summary.effectivePractice,
                accentColor: Color(hex: "#8BA4B0")
            )

            reflectionCard(
                icon: "lightbulb.fill",
                title: "Recommendation",
                text: summary.recommendation,
                accentColor: Color(hex: "#D4AF37")
            )
        }
        .padding(16)
    }

    // MARK: - Day Score

    private func dayScoreView(_ score: Int) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "#C7E8DE").opacity(0.10), lineWidth: 6)
                    .frame(width: 72, height: 72)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10.0)
                    .stroke(
                        scoreColor(score),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor(score))
            }

            Text("Day Score")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 8...10: return Color(hex: "#10B981")
        case 5...7: return Color(hex: "#D4AF37")
        default: return Color(hex: "#7B6B9E")
        }
    }

    // MARK: - Stress Timeline

    private var stressTimeline: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Weather")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

            HStack(spacing: 4) {
                ForEach(hourlyWeatherDots(), id: \.hour) { dot in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(dot.color)
                            .frame(width: 8, height: 8)

                        if dot.hour % 3 == 0 {
                            Text("\(dot.hour)")
                                .font(.system(size: 8))
                                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.40))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func hourlyWeatherDots() -> [HourDot] {
        let entries = fetchTodayEntries()
        let calendar = Calendar.current

        // Group entries by hour
        var hourWeather: [Int: InnerWeather] = [:]
        for entry in entries {
            let hour = calendar.component(.hour, from: entry.timestamp)
            if let weather = InnerWeather(rawValue: entry.weather) {
                hourWeather[hour] = weather
            }
        }

        // Build dots for hours 8-20 (working day)
        return (8...20).map { hour in
            let color: Color
            if let weather = hourWeather[hour] {
                switch weather {
                case .clear: color = Color(hex: "#10B981")
                case .cloudy: color = Color(hex: "#8BA4B0")
                case .stormy: color = Color(hex: "#7B6B9E")
                }
            } else {
                color = Color(hex: "#C7E8DE").opacity(0.15)
            }
            return HourDot(hour: hour, color: color)
        }
    }

    // MARK: - Reflection Card

    private func reflectionCard(icon: String, title: String, text: String, accentColor: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))

                Text(text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.92))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Close Bar

    private var closeBar: some View {
        Button(action: {
            appState.showDashboard()
        }) {
            Text("Close")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "#10B981"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: - Data Fetching

    private func fetchTodayEntries() -> [StressEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<StressEntry>(
            predicate: #Predicate { $0.timestamp >= startOfDay },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchTodayPractices() -> [PracticeSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.startedAt >= startOfDay },
            sortBy: [SortDescriptor(\.startedAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchTodayDismissals() -> [DismissalEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DismissalEvent>(
            predicate: #Predicate { $0.timestamp >= startOfDay },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadSummary() async {
        let entries = fetchTodayEntries()
        guard !entries.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        // Convert SwiftData objects to Sendable snapshots
        let entrySnapshots = entries.map { entry in
            StressEntrySnapshot(
                timestamp: entry.timestamp,
                weather: entry.weather,
                confidence: entry.confidence,
                signals: entry.signals,
                nudgeType: entry.nudgeType,
                nudgeMessage: entry.nudgeMessage
            )
        }

        let practiceSnapshots = fetchTodayPractices().map { session in
            PracticeSessionSnapshot(
                practiceID: session.practiceID,
                startedAt: session.startedAt,
                weatherBefore: session.weatherBefore,
                weatherAfter: session.weatherAfter,
                wasCompleted: session.wasCompleted,
                whatHelped: session.whatHelped
            )
        }

        let dismissalSnapshots = fetchTodayDismissals().map { event in
            DismissalSnapshot(
                timestamp: event.timestamp,
                aiDetectedWeather: event.aiDetectedWeather,
                dismissalType: event.dismissalType
            )
        }

        do {
            let service = try DaySummaryService()
            summary = try await service.generateDaySummary(
                entries: entrySnapshots,
                practices: practiceSnapshots,
                dismissals: dismissalSnapshots
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Supporting Types

private struct HourDot {
    let hour: Int
    let color: Color
}
