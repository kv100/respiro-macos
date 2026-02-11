import SwiftUI
import SwiftData
import AppKit

@main
struct RespiroDesktopApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StressEntry.self,
            PracticeSession.self,
            DismissalEvent.self,
            UserPreferences.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .environment(appState)
                .modelContainer(sharedModelContainer)
                .frame(width: 360, height: 480)
                .preferredColorScheme(.dark)
                .task {
                    await setupMonitoring()
                }
        } label: {
            Image(systemName: appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz")
        }
        .menuBarExtraStyle(.window)
    }

    @MainActor
    private func setupMonitoring() async {
        let modelContext = sharedModelContainer.mainContext

        // Provide modelContext to AppState for StressEntry persistence
        appState.modelContext = modelContext

        // Wire up DemoModeService first
        let demoModeService = DemoModeService()
        appState.configureDemoMode(demoModeService)

        // Seed demo data if demo mode is enabled
        if demoModeService.isEnabled {
            demoModeService.seedDemoData(modelContext: modelContext)
        }

        // Wire NudgeEngine, DismissalLogger, SmartSuppression BEFORE vision client guard
        // These don't depend on the API key and are needed for demo mode nudge decisions
        let nudgeEngine = NudgeEngine()
        appState.configureNudgeEngine(nudgeEngine)

        let dismissalLogger = DismissalLogger(modelContext: modelContext)
        appState.configureDismissalLogger(dismissalLogger)

        let smartSuppression = SmartSuppression()
        appState.configureSmartSuppression(smartSuppression)

        let preferenceLearner = PreferenceLearner(modelContext: modelContext)
        let rankedPractices = preferenceLearner.rankedPracticeIDs()

        // Create vision client — proxy mode always works (no API key required)
        let screenMonitor = ScreenMonitor()
        let visionClient = ClaudeVisionClient()

        let service = MonitoringService(screenMonitor: screenMonitor, visionClient: visionClient)

        // Wire up weather callback — captures appState for @MainActor update
        let state = appState
        await service.setWeatherCallback { @Sendable weather, analysis in
            Task { @MainActor in
                state.updateWeather(weather, analysis: analysis)
            }
        }

        // Wire silence callback for real monitoring
        await service.setSilenceCallback { @Sendable silence in
            Task { @MainActor in
                state.lastSilenceDecision = silence
            }
        }

        appState.configureMonitoring(service: service)

        // Load initial learned patterns into monitoring service
        if let patterns = dismissalLogger.buildLearnedPatterns() {
            await service.updateLearnedPatterns(patterns)
        }

        // Update preferred practices
        await service.updatePreferredPractices(rankedPractices)

        // Build initial tool context from SwiftData
        let practiceDescriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let recentPractices = (try? modelContext.fetch(practiceDescriptor)) ?? []
        let practiceJSON = recentPractices.prefix(10).map { session in
            "{\"practiceID\":\"\(session.practiceID)\",\"weatherBefore\":\"\(session.weatherBefore)\",\"weatherAfter\":\"\(session.weatherAfter ?? "unknown")\",\"wasCompleted\":\(session.wasCompleted)}"
        }.joined(separator: ",")

        let weatherDescriptor = FetchDescriptor<StressEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let recentWeather = (try? modelContext.fetch(weatherDescriptor)) ?? []
        let weatherJSON = recentWeather.prefix(20).map { entry in
            "{\"weather\":\"\(entry.weather)\",\"confidence\":\(entry.confidence),\"timestamp\":\"\(entry.timestamp)\"}"
        }.joined(separator: ",")

        let toolContext = ToolContext(
            practiceHistory: "[\(practiceJSON)]",
            weatherHistory: "[\(weatherJSON)]",
            preferredPractices: rankedPractices
        )
        await service.updateToolContext(toolContext)

        // P6.5: Wake-from-sleep detection — trigger immediate check after 30s
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await service.triggerImmediateCheck()
            }
        }
    }
}
