import Foundation
import SwiftData

/// SwiftData model for persisted scenario history
@Model
final class ScenarioBankEntry: @unchecked Sendable {
    var id: String
    var name: String
    var scenarioDescription: String  // "description" is reserved, rename to scenarioDescription
    var hypothesis: String?
    var generatedAt: Date
    var usedInRound: Int

    init(id: String, name: String, description: String, hypothesis: String?, generatedAt: Date, usedInRound: Int) {
        self.id = id
        self.name = name
        self.scenarioDescription = description
        self.hypothesis = hypothesis
        self.generatedAt = generatedAt
        self.usedInRound = usedInRound
    }
}
