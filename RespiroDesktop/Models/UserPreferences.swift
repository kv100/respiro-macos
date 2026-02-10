import Foundation
import SwiftData

@Model
final class UserPreferences {
    var id: UUID
    var screenshotInterval: Int
    var activeHoursStart: Int
    var activeHoursEnd: Int
    var nudgeStyle: String
    var soundEnabled: Bool
    var showEncouragementNudges: Bool
    var preferredPracticeIDs: [String]
    var maxPracticeDuration: Int
    var learnedPatterns: String?

    init(
        id: UUID = UUID(),
        screenshotInterval: Int = 300,
        activeHoursStart: Int = 9,
        activeHoursEnd: Int = 18,
        nudgeStyle: String = "popover",
        soundEnabled: Bool = true,
        showEncouragementNudges: Bool = true,
        preferredPracticeIDs: [String] = [],
        maxPracticeDuration: Int = 90,
        learnedPatterns: String? = nil
    ) {
        self.id = id
        self.screenshotInterval = screenshotInterval
        self.activeHoursStart = activeHoursStart
        self.activeHoursEnd = activeHoursEnd
        self.nudgeStyle = nudgeStyle
        self.soundEnabled = soundEnabled
        self.showEncouragementNudges = showEncouragementNudges
        self.preferredPracticeIDs = preferredPracticeIDs
        self.maxPracticeDuration = maxPracticeDuration
        self.learnedPatterns = learnedPatterns
    }
}
