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
    }

    private let demoScenario: [DemoScenarioEntry] = [
        // 1. Start clear — user just opened app
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "clear",
                confidence: 0.85,
                signals: ["single app focused", "clean desktop"],
                nudgeType: nil,
                nudgeMessage: nil,
                suggestedPracticeID: nil
            ),
            delay: 10
        ),

        // 2. Getting cloudy — more tabs, emails
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "cloudy",
                confidence: 0.72,
                signals: ["multiple apps open", "email client active", "15+ browser tabs"],
                nudgeType: "encouragement",
                nudgeMessage: "Looks like things are picking up. You're handling it well.",
                suggestedPracticeID: nil
            ),
            delay: 12
        ),

        // 3. Still cloudy — context switching
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "cloudy",
                confidence: 0.78,
                signals: ["rapid app switching", "Slack notifications", "calendar showing meetings"],
                nudgeType: nil,
                nudgeMessage: nil,
                suggestedPracticeID: nil
            ),
            delay: 10
        ),

        // 4. Stormy! — stress detected
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "stormy",
                confidence: 0.88,
                signals: ["error messages visible", "many notifications", "video call fatigue", "cluttered desktop"],
                nudgeType: "practice",
                nudgeMessage: "I notice things are getting intense. A quick breathing exercise might help reset.",
                suggestedPracticeID: "physiological-sigh"
            ),
            delay: 15
        ),

        // 5. After practice — clearing up
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "cloudy",
                confidence: 0.70,
                signals: ["fewer apps open", "calmer desktop"],
                nudgeType: "acknowledgment",
                nudgeMessage: "Weather's clearing up — nice recovery.",
                suggestedPracticeID: nil
            ),
            delay: 12
        ),

        // 6. Clear again — recovered
        DemoScenarioEntry(
            response: StressAnalysisResponse(
                weather: "clear",
                confidence: 0.90,
                signals: ["focused on single task", "clean workspace"],
                nudgeType: nil,
                nudgeMessage: nil,
                suggestedPracticeID: nil
            ),
            delay: 10
        ),
    ]

    // MARK: - Public API

    /// Returns next mock analysis response (cycles through scenario)
    func nextAnalysis() -> StressAnalysisResponse {
        let entry = demoScenario[scenarioIndex]
        scenarioIndex = (scenarioIndex + 1) % demoScenario.count
        return entry.response
    }

    /// Start demo monitoring loop with shorter intervals
    func startDemoLoop(onUpdate: @escaping @Sendable (InnerWeather, StressAnalysisResponse) -> Void) {
        guard !isRunning else { return }
        isRunning = true
        scenarioIndex = 0

        demoTask?.cancel()
        demoTask = Task { [weak self] in
            await self?.demoLoop(onUpdate: onUpdate)
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

    /// Reset demo data seeded flag (for testing)
    func resetDemoDataSeed() {
        UserDefaults.standard.set(false, forKey: Self.demoDataSeededKey)
    }

    // MARK: - Private

    private func demoLoop(onUpdate: @escaping @Sendable (InnerWeather, StressAnalysisResponse) -> Void) async {
        while !Task.isCancelled && isRunning {
            let entry = demoScenario[scenarioIndex]
            let response = entry.response
            let weather = InnerWeather(rawValue: response.weather) ?? .clear

            // Call update on MainActor
            Task { @MainActor in
                onUpdate(weather, response)
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
