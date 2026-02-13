# SwiftData Patterns — Quick Reference

## Model Definition

```swift
import Foundation
import SwiftData

@Model
final class StressEntry {
    var id: UUID
    var timestamp: Date
    var weather: String          // "clear", "cloudy", "stormy"
    var confidence: Double
    var signals: [String]
    var nudgeType: String?
    var nudgeMessage: String?
    var suggestedPracticeID: String?
    var screenshotInterval: Int

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        weather: String,
        confidence: Double,
        signals: [String] = [],
        nudgeType: String? = nil,
        nudgeMessage: String? = nil,
        suggestedPracticeID: String? = nil,
        screenshotInterval: Int = 300
    ) {
        self.id = id
        self.timestamp = timestamp
        self.weather = weather
        self.confidence = confidence
        self.signals = signals
        self.nudgeType = nudgeType
        self.nudgeMessage = nudgeMessage
        self.suggestedPracticeID = suggestedPracticeID
        self.screenshotInterval = screenshotInterval
    }
}
```

## ModelContainer Setup

```swift
@main
struct RespiroDesktopApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: StressEntry.self, PracticeSession.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra { ... }
            .modelContainer(modelContainer)
    }
}
```

## Queries in SwiftUI Views

```swift
struct DashboardView: View {
    @Query(sort: \StressEntry.timestamp, order: .reverse)
    private var entries: [StressEntry]

    @Query(filter: #Predicate<PracticeSession> { $0.wasCompleted })
    private var completedPractices: [PracticeSession]

    var body: some View {
        // Use entries and completedPractices directly
    }
}
```

## Filtered Queries

```swift
// Last 24 hours
@Query(filter: #Predicate<StressEntry> {
    $0.timestamp > Date().addingTimeInterval(-86400)
}, sort: \StressEntry.timestamp, order: .reverse)
private var recentEntries: [StressEntry]

// Stormy weather only
@Query(filter: #Predicate<StressEntry> {
    $0.weather == "stormy"
})
private var stormyEntries: [StressEntry]
```

## CRUD in Services

```swift
// Insert
@MainActor
func saveEntry(_ response: StressAnalysisResponse, context: ModelContext) {
    let entry = StressEntry(
        weather: response.weather,
        confidence: response.confidence,
        signals: response.signals,
        nudgeType: response.nudgeType,
        nudgeMessage: response.nudgeMessage,
        suggestedPracticeID: response.suggestedPracticeID
    )
    context.insert(entry)
    try? context.save()
}

// Fetch with predicate
func fetchRecentEntries(context: ModelContext, hours: Int = 24) throws -> [StressEntry] {
    let cutoff = Date().addingTimeInterval(-Double(hours * 3600))
    let descriptor = FetchDescriptor<StressEntry>(
        predicate: #Predicate { $0.timestamp > cutoff },
        sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    return try context.fetch(descriptor)
}

// Delete
func deleteOldEntries(context: ModelContext, olderThan days: Int) throws {
    let cutoff = Date().addingTimeInterval(-Double(days * 86400))
    let descriptor = FetchDescriptor<StressEntry>(
        predicate: #Predicate { $0.timestamp < cutoff }
    )
    let old = try context.fetch(descriptor)
    for entry in old {
        context.delete(entry)
    }
    try context.save()
}

// Update
func markPracticeCompleted(_ session: PracticeSession, weatherAfter: String, context: ModelContext) {
    session.completedAt = Date()
    session.wasCompleted = true
    session.weatherAfter = weatherAfter
    try? context.save()
}
```

## ModelContext Access Patterns

```swift
// In SwiftUI views
@Environment(\.modelContext) private var modelContext

// In services (pass from caller)
func doWork(context: ModelContext) { ... }

// From ModelContainer
let context = modelContainer.mainContext  // @MainActor only
```

## Existing Models in Respiro

| Model                  | File                              | Purpose                     |
| ---------------------- | --------------------------------- | --------------------------- |
| `StressEntry`          | Models/StressEntry.swift          | Main stress data            |
| `PracticeSession`      | Models/PracticeSession.swift      | Practice completion records |
| `BehaviorMetrics`      | Models/BehaviorMetrics.swift      | Context switches, app focus |
| `SystemContext`        | Models/SystemContext.swift        | Active app, window count    |
| `UserBaseline`         | Models/UserBaseline.swift         | Personal baseline patterns  |
| `FalsePositivePattern` | Models/FalsePositivePattern.swift | Dismissal tracking          |

## Key Rules

- `@Model` classes are `final class` (not struct)
- All properties must be Codable-compatible types
- Use `UUID`, `Date`, `String`, `Double`, `Int`, `Bool`, `[String]`, optionals
- No custom enums in @Model (use raw String values)
- `ModelContainer` init in app entry point
- `ModelContext` for all CRUD operations
- Local storage only — no CloudKit for this project
- SwiftData handles persistence automatically on save
