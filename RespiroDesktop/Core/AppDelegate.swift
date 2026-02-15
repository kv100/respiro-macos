import SwiftUI
import SwiftData
import AppKit
import UserNotifications

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var menuBarController: MenuBarController?
    var appState: AppState?
    var sharedModelContainer: ModelContainer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let appState = appState,
              let modelContainer = sharedModelContainer else {
            print("AppDelegate: Missing appState or modelContainer")
            return
        }

        // Create MenuBarController
        menuBarController = MenuBarController(appState: appState, modelContainer: modelContainer)

        // Setup notifications
        setupNotifications()

        // Setup monitoring
        Task {
            await setupMonitoring(appState: appState, modelContainer: modelContainer)
        }
    }

    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // Request permission
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        // Register notification actions
        let startPracticeAction = UNNotificationAction(
            identifier: "START_PRACTICE",
            title: "Start Practice",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Not Now",
            options: []
        )
        let nudgeCategory = UNNotificationCategory(
            identifier: "NUDGE",
            actions: [startPracticeAction, dismissAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([nudgeCategory])
    }

    private func setupMonitoring(appState: AppState, modelContainer: ModelContainer) async {
        let modelContext = modelContainer.mainContext

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

        // Wire PlaytestService (uses same mode as vision client)
        let playtestService = PlaytestService(mode: visionClient.mode)
        appState.configurePlaytest(playtestService)

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

        // Wire diagnostic callback
        await service.setDiagnosticCallback { @Sendable msg in
            Task { @MainActor in
                state.monitoringDiagnostic = msg
            }
        }

        // Wire auto-pause callback (user idle 30+ min → pause monitoring)
        await service.setAutoPauseCallback { @Sendable in
            Task { @MainActor in
                state.handleAutoPause()
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

// MARK: - Notification Delegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionID = response.actionIdentifier
        Task { @MainActor [weak self] in
            guard let appState = self?.appState else { return }
            switch actionID {
            case "START_PRACTICE":
                if appState.pendingNudge?.shouldShow == true {
                    appState.showPractice()
                } else {
                    appState.showDashboard()
                }
            case "DISMISS":
                await appState.notifyDismissal(type: .imFine)
            default:
                // User tapped the notification itself -- open the app
                if appState.pendingNudge?.shouldShow == true {
                    appState.showNudge()
                } else {
                    appState.showDashboard()
                }
            }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
