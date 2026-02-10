import Foundation

enum InnerWeather: String, Codable, Sendable, CaseIterable {
    case clear
    case cloudy
    case stormy

    var sfSymbol: String {
        switch self {
        case .clear: return "sun.max"
        case .cloudy: return "cloud"
        case .stormy: return "cloud.bolt.rain"
        }
    }

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .stormy: return "Stormy"
        }
    }
}
