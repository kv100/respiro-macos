import SwiftUI

struct PlaytestView: View {
    let service: PlaytestService
    var onBack: () -> Void
    var onScenarioTap: ((PlaytestScenario) -> Void)?

    @State private var runningRotation: Double = 0
    @State private var showExitAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar
                .frame(height: 52)

            Divider()
                .background(Color.white.opacity(0.06))

            ScrollView {
                VStack(spacing: 0) {
                    roundsList

                    if service.isRunning {
                        progressSection
                            .transition(.opacity)
                    }

                    if let report = service.currentReport {
                        summarySection(report)
                            .transition(.opacity)
                    }

                    if let error = service.error {
                        errorSection(error)
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.never)
        }
        .frame(width: 360, height: 480)
        .background(Color(hex: "#142823"))
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: service.isRunning)
        .animation(.easeInOut(duration: 0.3), value: service.currentReport != nil)
        .alert("Tests are running", isPresented: $showExitAlert) {
            Button("Stop & Exit", role: .destructive) {
                service.stop()
                onBack()
            }
            Button("Keep Running", role: .cancel) { }
        } message: {
            Text("Tests are still running. Stop exploration and exit?")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: {
                if service.isRunning {
                    showExitAlert = true
                } else {
                    onBack()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                    Text("Back")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Color.white.opacity(0.60))
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "testtube.2")
                    .font(.system(size: 13, weight: .medium))
                Text("PLAYTEST")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Color.white.opacity(0.92))

            Spacer()

            exploreButton
        }
        .padding(.horizontal, 16)
    }

    private var exploreButton: some View {
        Button(action: {
            if service.isRunning {
                service.stop()
            } else {
                service.explore()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: service.isRunning ? "stop.fill" : "testtube.2")
                    .font(.system(size: 10, weight: .semibold))
                Text(service.isRunning ? "Stop" : "Explore")
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(service.isRunning ? Color(hex: "#D4AF37") : Color(hex: "#10B981"))
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rounds List

    private var roundsList: some View {
        VStack(spacing: 0) {
            ForEach(service.rounds) { round in
                roundSection(round)
            }
        }
    }

    private func roundSection(_ round: PlaytestRound) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Round header
            HStack(spacing: 6) {
                Image(systemName: round.isAIGenerated ? "brain.head.profile" : "flask")
                    .font(.system(size: 11, weight: .medium))

                Text(roundHeaderText(round))
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
            }
            .foregroundStyle(Color.white.opacity(0.60))
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Scenario rows
            ForEach(round.scenarios) { scenario in
                scenarioRow(scenario)
            }
        }
    }

    private func roundHeaderText(_ round: PlaytestRound) -> String {
        let count = round.scenarios.count
        if round.isAIGenerated {
            return "ROUND \(round.id) — AI-Generated (\(count)) \u{1F916}"
        } else {
            return "ROUND \(round.id) — Seed (\(count))"
        }
    }

    private func scenarioRow(_ scenario: PlaytestScenario) -> some View {
        let status = service.status(for: scenario.id)
        let eval = service.evaluation(for: scenario.id)

        return Button(action: { onScenarioTap?(scenario) }) {
            HStack(spacing: 10) {
                statusIcon(status)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.name)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)

                    if let hypothesis = scenario.hypothesis {
                        Text(hypothesis)
                            .font(.system(size: 11).italic())
                            .foregroundStyle(Color.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                // Behavioral complexity badge
                if hasBehavioralData(scenario) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 10))
                        Text(behavioralSummary(scenario))
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(behavioralColor(scenario))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(behavioralColor(scenario).opacity(0.2))
                    .cornerRadius(4)
                }

                if let eval = eval {
                    confidenceLabel(eval.confidence)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Icons

    @ViewBuilder
    private func statusIcon(_ status: PlaytestService.ScenarioStatus) -> some View {
        switch status {
        case .passed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#10B981"))
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#D4AF37"))
        case .running:
            Image(systemName: "arrow.trianglehead.2.clockwise")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#10B981"))
                .rotationEffect(.degrees(runningRotation))
                .onAppear {
                    runningRotation = 0
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        runningRotation = 360
                    }
                }
                .onDisappear {
                    withAnimation(.linear(duration: 0)) {
                        runningRotation = 0
                    }
                }
        case .pending:
            Image(systemName: "circle")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    // MARK: - Confidence

    private func confidenceLabel(_ confidence: Double) -> some View {
        let pct = Int(confidence * 100)
        return Text("\(pct)%")
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(confidenceColor(confidence))
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.80 {
            return Color(hex: "#10B981")
        } else if confidence >= 0.60 {
            return Color(hex: "#8BA4B0")
        } else {
            return Color(hex: "#D4AF37")
        }
    }

    // MARK: - Behavioral Metrics

    private func hasBehavioralData(_ scenario: PlaytestScenario) -> Bool {
        scenario.steps.contains { $0.behaviorMetrics != nil }
    }

    private func behavioralSummary(_ scenario: PlaytestScenario) -> String {
        guard let firstMetrics = scenario.steps.first(where: { $0.behaviorMetrics != nil })?.behaviorMetrics else {
            return ""
        }
        return String(format: "%.1f/min", firstMetrics.contextSwitchesPerMinute)
    }

    private func behavioralColor(_ scenario: PlaytestScenario) -> Color {
        guard let metrics = scenario.steps.first(where: { $0.behaviorMetrics != nil })?.behaviorMetrics else {
            return Color(hex: "#8BA4B0")
        }
        if metrics.contextSwitchesPerMinute > 5.0 {
            return Color(hex: "#A855F7") // purple
        }
        if metrics.contextSwitchesPerMinute > 2.0 {
            return Color(hex: "#EAB308") // gold
        }
        return Color(hex: "#10B981") // jade
    }

    // MARK: - Progress

    private var progressSection: some View {
        let completed = service.totalCount
        let total = service.allScenarios.count

        // Calculate current index if a scenario is running
        let currentIndex: Int? = {
            guard let currentID = service.currentScenarioID else { return nil }
            return service.allScenarios.firstIndex(where: { $0.id == currentID })
        }()

        // Progress for bar: completed + (currently running ? 0.5 : 0)
        let progressCount = Double(completed) + (currentIndex != nil ? 0.5 : 0.0)

        return VStack(spacing: 8) {
            Text(service.progressMessage)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.60))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#10B981"))
                        .frame(
                            width: total > 0
                                ? geo.size.width * CGFloat(progressCount) / CGFloat(total)
                                : 0,
                            height: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: progressCount)
                }
            }
            .frame(height: 6)

            // Show current running index or completed count
            if let index = currentIndex {
                Text("Running \(index + 1)/\(total)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color(hex: "#10B981"))
            } else {
                Text("\(completed)/\(total)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Summary

    private func summarySection(_ report: PlaytestReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headline
            Text("\(report.rounds.count) rounds \u{00B7} \(service.totalCount) scenarios \u{00B7} \(Int(report.overallConfidence * 100))% confidence")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))

            Text("\(service.seedCount) seed + \(service.generatedCount) AI-generated")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.60))

            // Counts
            HStack(spacing: 16) {
                statBadge(
                    icon: "checkmark.circle.fill",
                    count: service.passedCount,
                    label: "passed",
                    color: Color(hex: "#10B981")
                )
                statBadge(
                    icon: "exclamationmark.triangle.fill",
                    count: service.failedCount,
                    label: "failed",
                    color: Color(hex: "#D4AF37")
                )
                if !report.discoveries.isEmpty {
                    statBadge(
                        icon: "sparkle",
                        count: report.discoveries.count,
                        label: "discoveries",
                        color: Color(hex: "#8BA4B0")
                    )
                }
            }

            // Critical issues
            if !report.criticalIssues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Critical Issues")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#D4AF37"))

                    ForEach(report.criticalIssues, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\u{2022}")
                            Text(issue)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.72))
                    }
                }
            }

            // AI summary
            if !report.summary.isEmpty {
                Text(report.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action buttons
            HStack(spacing: 8) {
                Button(action: { service.explore() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "testtube.2")
                            .font(.system(size: 12))
                        Text("Explore Again")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#10B981").opacity(0.15))
                    )
                    .foregroundStyle(Color(hex: "#10B981"))
                }
                .buttonStyle(.plain)

                Button(action: { openReportsFolder() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                        Text("Open Folder")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                    )
                    .foregroundStyle(Color.white.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func statBadge(icon: String, count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text("\(count) \(label)")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.60))
        }
    }

    // MARK: - Error

    private func errorSection(_ error: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "#D4AF37"))

            Text(error)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "#D4AF37").opacity(0.08))
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Actions

    private func openReportsFolder() {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[Playtest] Failed to find Documents directory")
            return
        }

        let reportsDir = documents.appendingPathComponent("Respiro_Playtest_Reports", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: reportsDir.path) {
            try? fileManager.createDirectory(at: reportsDir, withIntermediateDirectories: true)
        }

        // Open in Finder
        NSWorkspace.shared.open(reportsDir)
    }
}
