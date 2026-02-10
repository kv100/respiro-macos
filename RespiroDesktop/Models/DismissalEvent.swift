import Foundation
import SwiftData

@Model
final class DismissalEvent {
    var id: UUID
    var timestamp: Date
    var stressEntryID: UUID
    var aiDetectedWeather: String
    var dismissalType: String
    var suggestedPracticeID: String?
    var contextSignals: [String]

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        stressEntryID: UUID,
        aiDetectedWeather: String,
        dismissalType: String,
        suggestedPracticeID: String? = nil,
        contextSignals: [String] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.stressEntryID = stressEntryID
        self.aiDetectedWeather = aiDetectedWeather
        self.dismissalType = dismissalType
        self.suggestedPracticeID = suggestedPracticeID
        self.contextSignals = contextSignals
    }
}
