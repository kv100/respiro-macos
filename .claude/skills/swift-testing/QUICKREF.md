# Swift Testing — Quick Reference

## Basic Test

```swift
import Testing
@testable import RespiroDesktop

@Suite("StressEntry Tests")
struct StressEntryTests {
    @Test("Creates entry with correct defaults")
    func creation() {
        let entry = StressEntry(weather: "clear", confidence: 0.8)
        #expect(entry.weather == "clear")
        #expect(entry.confidence == 0.8)
        #expect(entry.nudgeType == nil)
    }

    @Test("Weather validation rejects invalid values")
    func weatherValidation() {
        #expect(throws: ValidationError.invalidWeather) {
            try validateWeather("hurricane")
        }
    }
}
```

## Expectations

```swift
// Equality
#expect(value == expected)
#expect(value != unexpected)

// Boolean
#expect(condition)
#expect(!condition)

// Nil
#expect(optional == nil)
#expect(optional != nil)

// Throws
#expect(throws: SomeError.self) {
    try riskyOperation()
}

// No throw
#expect(throws: Never.self) {
    try safeOperation()
}
```

## Async Tests

```swift
@Test("Claude API returns valid response")
func apiResponse() async throws {
    let client = ClaudeVisionClient(apiKey: "test-key")
    let response = try await client.analyzeScreenshot(testImageData, context: testContext)
    #expect(response.weather == "clear" || response.weather == "cloudy" || response.weather == "stormy")
    #expect(response.confidence >= 0.0 && response.confidence <= 1.0)
}
```

## Parameterized Tests

```swift
@Test("Weather SF symbols are correct", arguments: [
    ("clear", "sun.max"),
    ("cloudy", "cloud"),
    ("stormy", "cloud.bolt.rain")
])
func weatherSymbols(weather: String, expectedSymbol: String) {
    let w = InnerWeather(rawValue: weather)!
    #expect(w.sfSymbol == expectedSymbol)
}
```

## Test Suites

```swift
@Suite("NudgeEngine Tests")
struct NudgeEngineTests {
    @Suite("Cooldown Logic")
    struct CooldownTests {
        @Test func respectsCooldownPeriod() async { }
        @Test func resetsAfterCooldown() async { }
    }

    @Suite("Suppression Logic")
    struct SuppressionTests {
        @Test func suppressesDuringVideoCall() async { }
        @Test func suppressesAfterDismissal() async { }
    }
}
```

## Setup and Teardown

```swift
@Suite("Database Tests")
struct DatabaseTests {
    let container: ModelContainer

    init() throws {
        container = try ModelContainer(
            for: StressEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func insertEntry() throws {
        let context = container.mainContext
        let entry = StressEntry(weather: "clear", confidence: 0.9)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<StressEntry>()
        let entries = try context.fetch(descriptor)
        #expect(entries.count == 1)
    }
}
```

## Tags

```swift
extension Tag {
    @Tag static var slow: Self
    @Tag static var integration: Self
    @Tag static var api: Self
}

@Test(.tags(.slow, .api))
func claudeAPIIntegration() async {
    // Tests that hit real Claude API
}
```

## Running Tests

```bash
# All tests
swift test

# Via Xcode
xcodebuild -scheme RespiroDesktop -destination 'platform=macOS' test

# Specific suite
swift test --filter StressEntryTests

# With tags
swift test --filter "tag:slow"

# Verbose output
swift test --verbose
```

## Testing Actors

```swift
@Test("MonitoringService respects interval")
func monitoringInterval() async {
    let service = MonitoringService(...)
    await service.startMonitoring()

    // Actor methods are called with await
    let isActive = await service.isActive
    #expect(isActive == true)

    await service.stopMonitoring()
    let isActiveAfter = await service.isActive
    #expect(isActiveAfter == false)
}
```

## Testing @Observable

```swift
@Test("AppState updates weather correctly")
@MainActor
func appStateWeather() {
    let state = AppState()
    state.currentWeather = .stormy
    #expect(state.currentWeather == .stormy)
    #expect(state.currentWeather.sfSymbol == "cloud.bolt.rain")
}
```

## Mocking Dependencies

```swift
// Protocol-based mocking
protocol ScreenCapturing: Sendable {
    func captureScreenshot() async throws -> Data
}

struct MockScreenMonitor: ScreenCapturing {
    let mockData: Data

    func captureScreenshot() async throws -> Data {
        return mockData
    }
}

@Test("Monitoring uses screen capture")
func monitoringCapture() async throws {
    let mock = MockScreenMonitor(mockData: testImageData)
    let service = MonitoringService(screenMonitor: mock)
    // ...
}
```
