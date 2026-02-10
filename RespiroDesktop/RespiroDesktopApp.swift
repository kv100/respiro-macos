import SwiftUI
import SwiftData

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
        let screenMonitor = ScreenMonitor()

        // Try to create vision client; if no API key, monitoring won't auto-start
        guard let visionClient = try? ClaudeVisionClient() else {
            return
        }

        let service = MonitoringService(screenMonitor: screenMonitor, visionClient: visionClient)
        let nudgeEngine = NudgeEngine()

        // Wire up weather callback — captures appState for @MainActor update
        let state = appState
        await service.setWeatherCallback { @Sendable weather, analysis in
            Task { @MainActor in
                state.updateWeather(weather, analysis: analysis)
            }
        }

        appState.configureMonitoring(service: service)
        appState.configureNudgeEngine(nudgeEngine)
    }
}
