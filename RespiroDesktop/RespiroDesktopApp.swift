import SwiftUI
import SwiftData
import AppKit

@main
struct RespiroDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        // Pass appState and modelContainer to AppDelegate
        let _ = {
            appDelegate.appState = appState
            appDelegate.sharedModelContainer = sharedModelContainer
        }()

        // Playtest window (only visible when opened explicitly)
        Window("Playtest", id: "playtest") {
            PlaytestWindowView()
                .environment(appState)
                .frame(width: 360, height: 480)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        // Window (not WindowGroup) prevents state restoration auto-open
    }
}
