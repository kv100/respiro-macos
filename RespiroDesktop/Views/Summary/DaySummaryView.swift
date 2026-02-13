import SwiftUI
import SwiftData

struct DaySummaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var summary: DaySummaryResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isThinkingExpanded = false
    @State private var displayedThinkingCharCount: Int = 0
    @State private var isThinkingAnimating: Bool = false
    @State private var thinkingAnimationTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .frame(height: 56)

            Divider()
                .background(Color(hex: "#C0E0D6").opacity(0.10))

            // Content
            ScrollView(.vertical, showsIndicators: false) {
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
        .frame(width: 420, height: 560)
        .background(Color(hex: "#142823"))
        .task {
            // Only auto-load if we have a cached summary in AppState
            if let cached = appState.cachedDaySummary {
                summary = cached
            }
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

            let count = fetchTodayEntries().count
            if count < 3 {
                Text("Need at least 3 readings for a summary.\nCurrently: \(count)/3")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    .multilineTextAlignment(.center)
            } else {
                Text("\(count) readings collected today")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.84))
                    .multilineTextAlignment(.center)

                Button("Generate Summary") {
                    Task { await loadSummary() }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#10B981"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#10B981").opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .buttonStyle(.plain)
            }
        }
        .padding(24)
    }

    // MARK: - Summary Content

    private func summaryContent(_ summary: DaySummaryResponse) -> some View {
        VStack(spacing: 12) {
            // Day score ring
            dayScoreView(summary.dayScore)

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

            // Refresh button
            Button {
                appState.cachedDaySummary = nil
                Task { await loadSummary() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Refresh")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.50))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(16)
    }

    // MARK: - Day Reflection Thinking

    @ViewBuilder
    private func dayReflectionThinkingPanel(text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isThinkingExpanded.toggle()
                }
                if isThinkingExpanded && displayedThinkingCharCount == 0 {
                    startThinkingAnimation(fullText: text)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))

                    Text("AI's Day Reflection")
                        .font(.system(size: 12, weight: .medium))

                    Spacer()

                    EffortIndicatorView(level: .max)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isThinkingExpanded ? 90 : 0))
                }
                .foregroundStyle(Color(hex: "#E0F4EE").opacity(0.60))
            }
            .buttonStyle(.plain)

            if isThinkingExpanded {
                let visibleText = String(text.prefix(displayedThinkingCharCount))
                ThinkingStreamView(
                    text: visibleText,
                    isStreaming: isThinkingAnimating
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(hex: "#C7E8DE").opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onDisappear {
            thinkingAnimationTask?.cancel()
        }
    }

    private func startThinkingAnimation(fullText: String) {
        guard displayedThinkingCharCount == 0 else { return }
        isThinkingAnimating = true

        thinkingAnimationTask = Task { @MainActor in
            let totalChars = fullText.count
            while displayedThinkingCharCount < totalChars {
                guard !Task.isCancelled else { return }
                displayedThinkingCharCount = min(displayedThinkingCharCount + 3, totalChars)
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
            }
            isThinkingAnimating = false
        }
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

        // Only show hours that have data
        let hoursWithData = (0...23).filter { hourWeather[$0] != nil }.sorted()
        if hoursWithData.isEmpty {
            return []
        }

        // Show range from first to last data hour, only dots with data
        let minHour = hoursWithData.first!
        let maxHour = hoursWithData.last!
        return (minHour...maxHour).compactMap { hour -> HourDot? in
            guard let weather = hourWeather[hour] else { return nil }
            let color: Color
            switch weather {
            case .clear: color = Color(hex: "#10B981")
            case .cloudy: color = Color(hex: "#8BA4B0")
            case .stormy: color = Color(hex: "#7B6B9E")
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

        // Minimum 3 entries required
        guard entries.count >= 3 else {
            errorMessage = "Need at least 3 stress readings to generate a summary. Currently: \(entries.count)"
            return
        }

        // Use cache if entry count hasn't changed
        if let cached = appState.cachedDaySummary,
           appState.cachedDaySummaryEntryCount == entries.count {
            summary = cached
            return
        }

        // Demo mode: use mock response (no API call needed)
        if appState.isDemoMode {
            isLoading = true
            errorMessage = nil
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            var mockResponse = DaySummaryResponse(
                overallMood: "Your day started like a clear morning -- focused and calm. By midday, clouds rolled in as meetings and messages piled up. A brief storm hit around 2 PM, but you recovered beautifully after a breathing practice.",
                stressPattern: "Stress peaked between 1-2 PM with rapid app switching (6.5 switches/min) and 23 open browser tabs. The trigger was a combination of post-meeting backlog and error dialogs in your code.",
                effectivePractice: "Box Breathing was your most effective practice today. After completing it during the storm, your weather improved from stormy to cloudy within 10 minutes, and you closed 15 browser tabs.",
                recommendation: "Tomorrow, consider a 2-minute breathing break before your afternoon meetings. Your data shows that pre-meeting practices reduce post-meeting stress peaks by about 40%.",
                dayScore: 7
            )
            mockResponse.thinkingText = """
            Looking at the full arc of today's data, I see a classic "meeting storm" pattern. The morning was productive with low context switching (0.4-0.8 switches/min) and focused Xcode work. The transition happened around 11 AM when email and Slack demands increased.

            The stormy period at 2 PM showed the highest behavioral stress markers: 6.5 context switches/min, 23 browser tabs, 12 unread Slack channels. But what's impressive is the recovery speed -- after box breathing, metrics dropped to 2.1 switches/min within 20 minutes.

            The user completed 2 practices today, both box breathing. For variety, I'd suggest trying grounding-54321 tomorrow -- body-based practices can complement breathing techniques well.

            Overall day score: 7/10. The storm was real but brief, and the user's self-awareness (completing a practice when needed) shows growing stress management skills.
            """

            summary = mockResponse
            appState.cachedDaySummary = mockResponse
            appState.cachedDaySummaryEntryCount = entries.count
            isLoading = false
            return
        }

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
            let result = try await service.generateDaySummary(
                entries: entrySnapshots,
                practices: practiceSnapshots,
                dismissals: dismissalSnapshots
            )
            summary = result
            // Cache the result
            appState.cachedDaySummary = result
            appState.cachedDaySummaryEntryCount = entries.count
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
