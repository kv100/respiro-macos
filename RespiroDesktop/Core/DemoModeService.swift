import Foundation
import SwiftUI
import SwiftData

// MARK: - DemoModeService

@MainActor
@Observable
final class DemoModeService {

    // MARK: - State

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.demoModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.demoModeKey) }
    }

    private var scenarioIndex: Int = 0
    private var demoTask: Task<Void, Never>?
    private var isRunning: Bool = false

    // MARK: - Constants

    private static let demoModeKey = "respiro_demo_mode_enabled"
    private static let demoDataSeededKey = "respiro_demo_data_seeded"

    // MARK: - Demo Scenario

    private struct DemoScenarioEntry {
        let response: StressAnalysisResponse
        let delay: TimeInterval
        /// If non-nil, this entry fires a silence decision instead of a normal update.
        let silenceDecision: SilenceDecision?

        init(response: StressAnalysisResponse, delay: TimeInterval, silenceDecision: SilenceDecision? = nil) {
            self.response = response
            self.delay = delay
            self.silenceDecision = silenceDecision
        }
    }

    // MARK: - Enhanced Demo Scenario (8 entries, showcasing all Opus features)

    private let demoScenario: [DemoScenarioEntry] = {
        // --- 1. Clear (low effort) — clean desktop, focused work ---
        var r1 = StressAnalysisResponse(
            weather: "clear",
            confidence: 0.88,
            signals: ["single app focused", "clean desktop", "organized workspace"],
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
        r1.thinkingText = "The user's desktop is clean and focused — a single code editor is open with no visible notifications. No signs of stress or overload. This is a good baseline reading."
        r1.effortLevel = .low

        // --- 2. Clear (low effort) — SILENCE DECISION: user in flow ---
        var r2 = StressAnalysisResponse(
            weather: "clear",
            confidence: 0.82,
            signals: ["code editor active", "terminal running", "steady typing cadence"],
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
        r2.thinkingText = "Desktop shows a code editor and terminal side by side. The user has been in this configuration for over 15 minutes with consistent typing. This is a deep focus state — any interruption, even a positive one, would break flow. Staying silent."
        r2.effortLevel = .low

        let silence2 = SilenceDecision(
            thinkingText: "I'm detecting a deep focus state — code editor and terminal side by side, steady typing cadence for 15+ minutes. Even though I could offer encouragement, interrupting flow would do more harm than good. The best thing I can do right now is stay quiet and let the user work.",
            effortLevel: .low,
            detectedWeather: .clear,
            signals: ["code editor active", "terminal running", "steady typing cadence"],
            flowDuration: 960 // 16 minutes
        )

        // --- 3. Cloudy (high effort) — emails piling up, encouragement nudge ---
        var r3 = StressAnalysisResponse(
            weather: "cloudy",
            confidence: 0.74,
            signals: ["multiple apps open", "email client with 8 unread", "15+ browser tabs", "Slack notifications visible"],
            nudgeType: "encouragement",
            nudgeMessage: "Looks like things are picking up. You're handling the multitasking well — take it one thing at a time.",
            suggestedPracticeID: nil
        )
        r3.thinkingText = "Context shift detected: the user moved from focused coding to a multi-app environment. Email client shows 8 unread messages, browser has 15+ tabs across 2 windows, and Slack is showing notification badges. This is a common post-meeting pattern — the user is processing accumulated messages. Stress isn't high yet, but the cognitive load is increasing. An encouragement nudge feels right here — not a practice suggestion, just acknowledgment."
        r3.effortLevel = .high

        // --- 4. Cloudy (high effort) — SILENCE DECISION: stress rising but user actively engaged ---
        var r4 = StressAnalysisResponse(
            weather: "cloudy",
            confidence: 0.78,
            signals: ["rapid app switching", "Slack thread open", "calendar showing back-to-back meetings", "email compose window"],
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
        r4.thinkingText = "Signals are intensifying — rapid app switching between Slack, email, and calendar. The user has back-to-back meetings visible and is composing an email. However, the typing is purposeful and the app switches follow a logical pattern (check calendar → compose reply → check Slack). This is controlled multitasking, not panic. Interrupting now would add to the cognitive load rather than reduce it. I'll hold off and check again soon."
        r4.effortLevel = .high

        let silence4 = SilenceDecision(
            thinkingText: "Stress signals are clearly rising — rapid app switching, back-to-back meetings on calendar, email and Slack competing for attention. My instinct is to intervene, but looking more carefully at the pattern: the user is composing a thoughtful reply, checking calendar for context, then updating Slack. This is purposeful task management, not overwhelm. Interrupting would add another demand for attention at exactly the wrong moment. I'll monitor and step in only if the pattern becomes erratic.",
            effortLevel: .high,
            detectedWeather: .cloudy,
            signals: ["rapid app switching", "Slack thread open", "calendar showing back-to-back meetings", "email compose window"]
        )

        // --- 5. Stormy (high effort) — practice nudge with full tool use chain ---
        var r5 = StressAnalysisResponse(
            weather: "stormy",
            confidence: 0.91,
            signals: ["23 open browser tabs across 4 windows", "3 error dialogs visible", "Slack 12 unread channels", "video call just ended", "cluttered desktop"],
            nudgeType: "practice",
            nudgeMessage: "I notice things have gotten pretty intense. A quick breathing exercise might help you reset before diving back in.",
            suggestedPracticeID: "box-breathing"
        )
        r5.thinkingText = "The user's desktop shows 23 open browser tabs across 4 windows, Slack has 12 unread channels, and there are 3 error dialogs visible. This pattern has been escalating over the past 30 minutes. I notice they just finished a video call — post-meeting stress is typically responsive to breathing exercises. Let me check what practices are available and what has worked for this user before."
        r5.effortLevel = .high
        r5.toolUseLog = [
            ToolCall(name: "get_practice_catalog", input: "{\"category\": \"breathing\"}"),
            ToolCall(name: "get_user_history", input: "{\"days\": 7, \"include_ratings\": true}"),
            ToolCall(name: "suggest_practice", input: "{\"practice_id\": \"box-breathing\", \"reason\": \"Post-meeting stress responds well to structured breathing. User completed box breathing twice this week with positive ratings.\"}")
        ]
        r5.practiceReason = "Post-meeting stress responds well to structured breathing. You've done box breathing twice this week and rated it helpful both times."

        // --- 6. Cloudy (low effort) — things calming down, acknowledgment ---
        var r6 = StressAnalysisResponse(
            weather: "cloudy",
            confidence: 0.70,
            signals: ["fewer apps open", "calmer desktop", "browser tabs reduced to 8"],
            nudgeType: "acknowledgment",
            nudgeMessage: "The storm is passing — nice recovery. Your focus is coming back.",
            suggestedPracticeID: nil
        )
        r6.thinkingText = "Marked improvement since the practice session. Browser tabs are down from 23 to 8, error dialogs cleared, Slack notifications addressed. The user's workspace is noticeably more organized. This recovery pattern is consistent with their history — breathing practices tend to help them reset and prioritize. A brief acknowledgment will reinforce the positive behavior without being intrusive."
        r6.effortLevel = .low

        // --- 7. Clear (low effort) — back to focused work ---
        var r7 = StressAnalysisResponse(
            weather: "clear",
            confidence: 0.85,
            signals: ["single app focused", "notifications cleared", "clean workspace"],
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
        r7.thinkingText = "Full recovery — the user is back to a single-app focus state with a clean desktop. The storm-to-clear arc completed in about 20 minutes. No intervention needed."
        r7.effortLevel = .low

        // --- 8. Clear (low effort) — sustained calm, final check ---
        var r8 = StressAnalysisResponse(
            weather: "clear",
            confidence: 0.92,
            signals: ["focused work session", "minimal browser tabs", "no notifications visible"],
            nudgeType: nil,
            nudgeMessage: nil,
            suggestedPracticeID: nil
        )
        r8.thinkingText = "Sustained calm. The user has maintained focus for the past two check-ins. Workspace is clean, tabs minimal. Today's pattern — clear to stormy to clear — shows effective stress management. This is exactly the kind of day where the coaching model proves its value."
        r8.effortLevel = .low

        return [
            DemoScenarioEntry(response: r1, delay: 10),
            DemoScenarioEntry(response: r2, delay: 10, silenceDecision: silence2),
            DemoScenarioEntry(response: r3, delay: 12),
            DemoScenarioEntry(response: r4, delay: 10, silenceDecision: silence4),
            DemoScenarioEntry(response: r5, delay: 15),
            DemoScenarioEntry(response: r6, delay: 12),
            DemoScenarioEntry(response: r7, delay: 10),
            DemoScenarioEntry(response: r8, delay: 10),
        ]
    }()

    // MARK: - Public API

    /// Returns next mock analysis response (cycles through scenario)
    func nextAnalysis() -> StressAnalysisResponse {
        let entry = demoScenario[scenarioIndex]
        scenarioIndex = (scenarioIndex + 1) % demoScenario.count
        return entry.response
    }

    /// Start demo monitoring loop with shorter intervals
    func startDemoLoop(
        onUpdate: @escaping @Sendable (InnerWeather, StressAnalysisResponse) -> Void,
        onSilenceDecision: (@Sendable (SilenceDecision) -> Void)? = nil
    ) {
        guard !isRunning else { return }
        isRunning = true
        scenarioIndex = 0

        demoTask?.cancel()
        demoTask = Task { [weak self] in
            await self?.demoLoop(onUpdate: onUpdate, onSilenceDecision: onSilenceDecision)
        }
    }

    func stopDemoLoop() {
        isRunning = false
        demoTask?.cancel()
        demoTask = nil
    }

    // MARK: - Demo Data Seeding (D6.1)

    /// Pre-seed a full day of demo data for Day Summary feature
    func seedDemoData(modelContext: ModelContext) {
        // Check if already seeded
        let alreadySeeded = UserDefaults.standard.bool(forKey: Self.demoDataSeededKey)
        if alreadySeeded {
            return
        }

        let calendar = Calendar.current
        let now = Date()
        guard let todayStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) else { return }

        // Pattern: clear → clear → cloudy → cloudy → stormy → cloudy → clear → clear
        let weatherPattern: [InnerWeather] = [.clear, .clear, .cloudy, .cloudy, .stormy, .cloudy, .clear, .clear]
        let confidencePattern: [Double] = [0.85, 0.82, 0.75, 0.78, 0.88, 0.72, 0.90, 0.87]

        // Create 8 StressEntries from 9:00 to 17:00 (every hour)
        for (index, weather) in weatherPattern.enumerated() {
            let timestamp = calendar.date(byAdding: .hour, value: index, to: todayStart) ?? now

            let entry = StressEntry(
                timestamp: timestamp,
                weather: weather.rawValue,
                confidence: confidencePattern[index],
                signals: demoSignals(for: weather),
                nudgeType: index == 4 ? "practice" : nil, // Nudge during stormy period
                nudgeMessage: index == 4 ? "Things are getting intense. Consider a breathing practice." : nil,
                suggestedPracticeID: index == 4 ? "physiological-sigh" : nil,
                screenshotInterval: 3600
            )
            modelContext.insert(entry)
        }

        // Add 2 PracticeSessions
        // Session 1: 11:00 (after 2nd entry), completed
        let practice1Time = calendar.date(byAdding: .hour, value: 2, to: todayStart) ?? now
        let practice1 = PracticeSession(
            practiceID: "box-breathing",
            startedAt: practice1Time,
            completedAt: calendar.date(byAdding: .minute, value: 3, to: practice1Time),
            weatherBefore: "cloudy",
            weatherAfter: "clear",
            wasCompleted: true,
            triggeredByNudge: false,
            whatHelped: ["felt calmer", "easier to focus"]
        )
        modelContext.insert(practice1)

        // Session 2: 14:00 (after stormy), completed
        let practice2Time = calendar.date(byAdding: .hour, value: 5, to: todayStart) ?? now
        let practice2 = PracticeSession(
            practiceID: "physiological-sigh",
            startedAt: practice2Time,
            completedAt: calendar.date(byAdding: .minute, value: 2, to: practice2Time),
            weatherBefore: "stormy",
            weatherAfter: "cloudy",
            wasCompleted: true,
            triggeredByNudge: true,
            whatHelped: ["quick relief", "cleared head"]
        )
        modelContext.insert(practice2)

        // Add 1 DismissalEvent at 10:30
        let dismissalTime = calendar.date(byAdding: .minute, value: 90, to: todayStart) ?? now
        let dismissal = DismissalEvent(
            timestamp: dismissalTime,
            stressEntryID: UUID(),
            aiDetectedWeather: "cloudy",
            dismissalType: "im_fine",
            contextSignals: ["email client active", "multiple tabs"]
        )
        modelContext.insert(dismissal)

        // Save and mark as seeded
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: Self.demoDataSeededKey)
    }

    /// Clear all demo data when disabling demo mode
    func clearDemoData(modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)

        // Delete all StressEntry from today
        let stressDescriptor = FetchDescriptor<StressEntry>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        if let entries = try? modelContext.fetch(stressDescriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }

        // Delete all PracticeSession from today
        let practiceDescriptor = FetchDescriptor<PracticeSession>(
            predicate: #Predicate { $0.startedAt >= todayStart }
        )
        if let sessions = try? modelContext.fetch(practiceDescriptor) {
            for session in sessions {
                modelContext.delete(session)
            }
        }

        // Delete all DismissalEvent from today
        let dismissalDescriptor = FetchDescriptor<DismissalEvent>(
            predicate: #Predicate { $0.timestamp >= todayStart }
        )
        if let dismissals = try? modelContext.fetch(dismissalDescriptor) {
            for dismissal in dismissals {
                modelContext.delete(dismissal)
            }
        }

        // Save changes
        try? modelContext.save()

        // Reset seeded flag
        UserDefaults.standard.removeObject(forKey: Self.demoDataSeededKey)
    }

    /// Reset demo data seeded flag (for testing)
    func resetDemoDataSeed() {
        UserDefaults.standard.set(false, forKey: Self.demoDataSeededKey)
    }

    // MARK: - Private

    private func demoLoop(
        onUpdate: @escaping @Sendable (InnerWeather, StressAnalysisResponse) -> Void,
        onSilenceDecision: (@Sendable (SilenceDecision) -> Void)?
    ) async {
        while !Task.isCancelled && isRunning {
            let entry = demoScenario[scenarioIndex]
            let response = entry.response
            let weather = InnerWeather(rawValue: response.weather) ?? .clear

            if let silence = entry.silenceDecision {
                // Fire silence decision callback — AI chose NOT to interrupt
                if let callback = onSilenceDecision {
                    Task { @MainActor in
                        callback(silence)
                    }
                }
                // Also fire normal update so weather icon updates
                Task { @MainActor in
                    onUpdate(weather, response)
                }
            } else {
                // Normal analysis update
                Task { @MainActor in
                    onUpdate(weather, response)
                }
            }

            scenarioIndex = (scenarioIndex + 1) % demoScenario.count

            // Sleep for demo interval
            let sleepNanos = UInt64(entry.delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: sleepNanos)
        }
    }

    private func demoSignals(for weather: InnerWeather) -> [String] {
        switch weather {
        case .clear:
            return ["single app focused", "clean desktop", "organized workspace"]
        case .cloudy:
            return ["multiple apps open", "email client active", "browser tabs visible"]
        case .stormy:
            return ["error messages visible", "many notifications", "cluttered desktop", "rapid switching"]
        }
    }
}
