import Foundation
import SwiftData

@Model
final class PracticeSession {
    var id: UUID
    var practiceID: String
    var startedAt: Date
    var completedAt: Date?
    var weatherBefore: String
    var weatherAfter: String?
    var wasCompleted: Bool
    var triggeredByNudge: Bool
    var triggeringEntryID: UUID?
    var whatHelped: [String]?

    init(
        id: UUID = UUID(),
        practiceID: String,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        weatherBefore: String,
        weatherAfter: String? = nil,
        wasCompleted: Bool = false,
        triggeredByNudge: Bool = false,
        triggeringEntryID: UUID? = nil,
        whatHelped: [String]? = nil
    ) {
        self.id = id
        self.practiceID = practiceID
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.weatherBefore = weatherBefore
        self.weatherAfter = weatherAfter
        self.wasCompleted = wasCompleted
        self.triggeredByNudge = triggeredByNudge
        self.triggeringEntryID = triggeringEntryID
        self.whatHelped = whatHelped
    }
}
