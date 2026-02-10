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
        } label: {
            Image(systemName: appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz")
        }
        .menuBarExtraStyle(.window)
    }
}
