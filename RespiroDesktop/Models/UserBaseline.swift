import Foundation
import SwiftData

/// User's personal behavioral baseline, learned from 7+ days of history.
/// Used to detect deviations that might indicate stress.
@Model
final class UserBaseline {
    var userID: String
    var avgTabCount: Double
    var avgContextSwitchRate: Double
    var normalAppMix: [String: Double]
    var typicalSessionLength: TimeInterval
    var weekdayPattern: [Int: Double]
    var timeOfDayPattern: [Int: Double]
    var lastUpdated: Date

    init(userID: String) {
        self.userID = userID
        self.avgTabCount = 0.0
        self.avgContextSwitchRate = 0.0
        self.normalAppMix = [:]
        self.typicalSessionLength = 0.0
        self.weekdayPattern = [:]
        self.timeOfDayPattern = [:]
        self.lastUpdated = Date()
    }
}
