# macOS Menu Bar App — Quick Reference

## NSStatusItem Setup

```swift
@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        // SF Symbol icon (template = adapts to light/dark)
        button.image = NSImage(systemSymbolName: "sun.max", accessibilityDescription: "Respiro")
        button.image?.isTemplate = true

        // Handle left + right clicks
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }
}
```

## Left Click → Popover

```swift
private func setupPopover() {
    let popover = NSPopover()
    popover.contentSize = NSSize(width: 360, height: 480)
    popover.behavior = .transient  // Closes when clicking outside
    popover.animates = true

    let mainView = MainView()
        .environment(appState)
        .modelContainer(sharedModelContainer)
        .preferredColorScheme(.dark)
        .frame(width: 360, height: 480)

    popover.contentViewController = NSHostingController(rootView: mainView)
    self.popover = popover
}

private func togglePopover(_ sender: NSStatusBarButton) {
    if popover?.isShown == true {
        popover?.close()
    } else {
        popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)  // Ensure popover gets focus
    }
}
```

## Right Click → Context Menu

```swift
private func showMenu(_ sender: NSStatusBarButton) {
    let menu = NSMenu()

    let monitoringTitle = appState.isMonitoring ? "Pause Monitoring" : "Start Monitoring"
    let monitoringItem = NSMenuItem(title: monitoringTitle, action: #selector(toggleMonitoring), keyEquivalent: "")
    monitoringItem.target = self
    menu.addItem(monitoringItem)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "Quit Respiro", action: #selector(quit), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    // Temporarily set menu, then remove (to allow left click to work again)
    statusItem?.menu = menu
    statusItem?.button?.performClick(nil)
    DispatchQueue.main.async { [weak self] in
        self?.statusItem?.menu = nil
    }
}
```

## Detecting Left vs Right Click

```swift
@objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
    guard let event = NSApp.currentEvent else { return }

    if event.type == .rightMouseUp {
        showMenu(sender)
    } else {
        togglePopover(sender)
    }
}
```

## Dynamic Icon Updates

```swift
func updateIcon() {
    let symbolName = appState.isMonitoring ? appState.currentWeather.sfSymbol : "moon.zzz"

    if let button = statusItem?.button {
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Respiro")
        button.image?.isTemplate = true
    }
}
```

## Observing State Changes (@Observable)

```swift
private func startObservingAppState() {
    Task { @MainActor in
        while true {
            await Task.yield()
            withObservationTracking {
                _ = appState.currentWeather
                _ = appState.isMonitoring
            } onChange: { [weak self] in
                Task { @MainActor in
                    self?.updateIcon()
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
    }
}
```

## AppDelegate Wiring

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController(
            appState: appState,
            modelContainer: modelContainer
        )
    }
}
```

## SwiftUI MenuBarExtra Alternative

```swift
// Simpler approach (used in some views):
@main
struct RespiroDesktopApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MainView()
                .environment(appState)
                .frame(width: 360, height: 480)
                .preferredColorScheme(.dark)
        } label: {
            Image(systemName: appState.currentWeather.sfSymbol)
        }
        .menuBarExtraStyle(.window)
    }
}

// NOTE: NSStatusItem approach gives more control (right-click menu, etc.)
```

## Weather SF Symbols

```swift
enum InnerWeather: String, Sendable {
    case clear, cloudy, stormy

    var sfSymbol: String {
        switch self {
        case .clear:  return "sun.max"
        case .cloudy: return "cloud"
        case .stormy: return "cloud.bolt.rain"
        }
    }
}
// Paused state: "moon.zzz"
```

## Key macOS Patterns

- `NSApp.setActivationPolicy(.accessory)` — hide dock icon
- `NSApp.activate(ignoringOtherApps: true)` — bring popover to front
- `.transient` popover behavior — auto-close on outside click
- `NSStatusItem.variableLength` — icon width adapts
- `button.image?.isTemplate = true` — adapts to menu bar color
- `NSHostingController` — bridges SwiftUI into NSPopover
