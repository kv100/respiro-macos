import Foundation
import SwiftData

@Model
final class StressEntry {
    var id: UUID
    var timestamp: Date
    var weather: String
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
