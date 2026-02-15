import SwiftUI
import SwiftData
import AppKit

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var appState: AppState
    private var sharedModelContainer: ModelContainer

    nonisolated init(appState: AppState, modelContainer: ModelContainer) {
        self.appState = appState
        self.sharedModelContainer = modelContainer
        super.init()

        Task { @MainActor in
            self.setupStatusItem()
            self.setupPopover()
            self.startObservingAppState()
        }
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            print("Failed to create status bar button")
            return
        }

        // Initial icon
        button.image = NSImage(systemSymbolName: "moon.zzz", accessibilityDescription: "Respiro")
        button.image?.isTemplate = true

        // Handle both left and right clicks
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu(sender)
        } else {
            togglePopover(sender)
        }
    }

    // MARK: - Popover (Left Click)

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 560)
        popover.behavior = .transient // Closes when clicking outside
        popover.animates = true

        let mainView = MainView()
            .environment(appState)
            .modelContainer(sharedModelContainer)
            .preferredColorScheme(.dark)
            .frame(width: 420, height: 560)
            .ignoresSafeArea()

        popover.contentViewController = NSHostingController(rootView: mainView)
        self.popover = popover
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover?.isShown == true {
            popover?.close()
        } else {
            popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            // Activate app to ensure popover receives focus
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showPopover() {
        guard let button = statusItem?.button else { return }
        if popover?.isShown != true {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Context Menu (Right Click)

    private func showMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        // Start/Pause Monitoring
        let monitoringTitle = appState.isMonitoring ? "Pause Monitoring" : "Start Monitoring"
        let monitoringItem = NSMenuItem(
            title: monitoringTitle,
            action: #selector(toggleMonitoring),
            keyEquivalent: ""
        )
        monitoringItem.target = self
        menu.addItem(monitoringItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Respiro",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Temporarily set menu to display it
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)

        // Remove menu after showing (to allow left click to work)
        // Use async to ensure menu is shown first
        DispatchQueue.main.async { [weak self] in
            self?.statusItem?.menu = nil
        }
    }

    @objc private func toggleMonitoring() {
        Task { @MainActor in
            await appState.toggleMonitoring()
            updateIcon()
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Icon Updates

    func updateIcon() {
        let symbolName = appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz"

        if let button = statusItem?.button {
            // Simple icon update (no animation to avoid Sendable warnings)
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Respiro")
            button.image?.isTemplate = true
        }
    }

    // MARK: - State Observation

    private func startObservingAppState() {
        // Update icon immediately
        updateIcon()

        // Use withObservationTracking to watch AppState changes
        Task { @MainActor in
            while true {
                await Task.yield()

                withObservationTracking {
                    // Read observed properties to register dependencies
                    _ = appState.currentWeather
                    _ = appState.isMonitoring
                    _ = appState.currentScreen
                } onChange: { [weak self] in
                    Task { @MainActor in
                        self?.updateIcon()
                        // Auto-open popover when nudge arrives
                        if self?.appState.currentScreen == .nudge {
                            self?.showPopover()
                        }
                    }
                }

                // Small delay to avoid tight loop
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
    }
}
