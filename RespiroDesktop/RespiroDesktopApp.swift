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
            UserBaseline.self,
            BehaviorDataEntry.self,
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

        // Menu bar only app — no windows in Scene (popover handles all UI)
        Settings { EmptyView() }
    }
}
