# Swift 6 Patterns — Quick Reference

## Sendable Conformance

```swift
// All shared types MUST be Sendable
struct UserProfile: Codable, Equatable, Sendable {
    let id: UUID
    let name: String
}

// Actors for shared mutable state
actor DataManager {
    private var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? { cache[key] }
    func set(_ key: String, data: Data) { cache[key] = data }
}
```

## Async/Await

```swift
// Always prefer async/await over completion handlers
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}

// Task groups for parallel work
func fetchAll(ids: [String]) async throws -> [Item] {
    try await withThrowingTaskGroup(of: Item.self) { group in
        for id in ids {
            group.addTask { try await fetch(id: id) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

## Error Handling

```swift
// Typed errors
enum APIError: Error, Sendable {
    case networkError(URLError)
    case decodingError(DecodingError)
    case serverError(statusCode: Int)
}

// do-catch pattern
do {
    let data = try await fetchData()
} catch let error as APIError {
    // Handle specific errors
} catch {
    // Handle unknown errors
}
```

## Property Wrappers

```swift
// @MainActor for UI updates
@MainActor
final class ViewModel: ObservableObject {
    @Published var items: [Item] = []
}

// Custom property wrapper
@propertyWrapper
struct Clamped<Value: Comparable> {
    var value: Value
    let range: ClosedRange<Value>

    var wrappedValue: Value {
        get { value }
        set { value = min(max(range.lowerBound, newValue), range.upperBound) }
    }
}
```

## Result Builders

```swift
@resultBuilder
struct ArrayBuilder<Element> {
    static func buildBlock(_ components: Element...) -> [Element] {
        components
    }
}
```

## Extensions

```swift
extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
}
```

## Protocols

```swift
protocol DataFetching: Sendable {
    func fetch(id: String) async throws -> Data
}

// Protocol with associated type
protocol Repository: Sendable {
    associatedtype Entity: Sendable
    func get(id: UUID) async throws -> Entity?
    func save(_ entity: Entity) async throws
}
```

## Never Force Unwrap

```swift
// Bad
let value = dictionary["key"]!

// Good
guard let value = dictionary["key"] else {
    throw Error.missingKey
}

// Or
let value = dictionary["key", default: defaultValue]
```
