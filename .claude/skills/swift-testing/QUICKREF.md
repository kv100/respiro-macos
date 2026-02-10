# Swift Testing — Quick Reference

## Basic Test

```swift
import Testing
@testable import Respiro

@Suite("Calculator Tests")
struct CalculatorTests {
    @Test("Addition works correctly")
    func addition() {
        let result = Calculator.add(2, 3)
        #expect(result == 5)
    }

    @Test("Division by zero throws")
    func divisionByZero() {
        #expect(throws: CalculatorError.divisionByZero) {
            try Calculator.divide(10, by: 0)
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
@Test("Async fetch returns data")
func asyncFetch() async throws {
    let data = try await client.fetch()
    #expect(data.count > 0)
}
```

## Parameterized Tests

```swift
@Test("Validation works", arguments: [
    ("valid@email.com", true),
    ("invalid", false),
    ("", false)
])
func emailValidation(email: String, expected: Bool) {
    let result = Validator.isValidEmail(email)
    #expect(result == expected)
}

// Multiple argument sources
@Test(arguments: [1, 2, 3], ["a", "b", "c"])
func combinedArgs(number: Int, letter: String) {
    // Tests all combinations
}
```

## Test Suites

```swift
@Suite("Feature Tests")
struct FeatureTests {
    @Suite("Unit Tests")
    struct UnitTests {
        @Test func unitTest1() { }
        @Test func unitTest2() { }
    }

    @Suite("Integration Tests")
    struct IntegrationTests {
        @Test func integrationTest1() async { }
    }
}
```

## Setup and Teardown

```swift
@Suite("Database Tests")
struct DatabaseTests {
    let database: Database

    init() async throws {
        database = try await Database.createTest()
    }

    deinit {
        database.cleanup()
    }

    @Test func insert() async throws {
        try await database.insert(Item.mock)
        let items = try await database.fetchAll()
        #expect(items.count == 1)
    }
}
```

## TCA TestStore

```swift
import Testing
import ComposableArchitecture
@testable import Respiro

@Suite("BreathingFeature Tests")
struct BreathingFeatureTests {
    @Test("Start breathing updates state")
    func startBreathing() async {
        let clock = TestClock()

        let store = TestStore(
            initialState: BreathingFeature.State()
        ) {
            BreathingFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        await store.send(.startBreathing) {
            $0.isAnimating = true
        }

        await clock.advance(by: .milliseconds(16))

        await store.receive(.tick) {
            $0.progress = 0.016
        }
    }
}
```

## Mocking Dependencies

```swift
@Test("Fetch handles error")
func fetchError() async {
    let store = TestStore(
        initialState: DataFeature.State()
    ) {
        DataFeature()
    } withDependencies: {
        $0.apiClient.fetch = {
            throw APIError.networkError
        }
    }

    await store.send(.fetch) {
        $0.isLoading = true
    }

    await store.receive(.fetchResponse(.failure)) {
        $0.isLoading = false
        $0.error = "Network error"
    }
}
```

## Tags

```swift
extension Tag {
    @Tag static var slow: Self
    @Tag static var integration: Self
}

@Test(.tags(.slow, .integration))
func slowIntegrationTest() async {
    // Long running test
}
```

## Running Tests

```bash
# All tests
swift test

# Specific suite
swift test --filter BreathingFeatureTests

# With tags
swift test --filter "tag:slow"

# Verbose output
swift test --verbose
```
