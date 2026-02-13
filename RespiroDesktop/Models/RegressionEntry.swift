import Foundation
import SwiftData

// MARK: - Regression Entry Model

/// SwiftData model tracking failed scenarios for regression testing
@Model
final class RegressionEntry: @unchecked Sendable {
    var scenarioID: String
    var scenarioName: String
    var originalRound: Int
    var firstFailedAt: Date
    var lastTestedAt: Date
    var status: String  // stillFailing, fixed, regression
    var fixedAt: Date?
    var consecutivePasses: Int

    init(
        scenarioID: String,
        scenarioName: String,
        originalRound: Int,
        firstFailedAt: Date = Date(),
        lastTestedAt: Date = Date(),
        status: String = "stillFailing",
        fixedAt: Date? = nil,
        consecutivePasses: Int = 0
    ) {
        self.scenarioID = scenarioID
        self.scenarioName = scenarioName
        self.originalRound = originalRound
        self.firstFailedAt = firstFailedAt
        self.lastTestedAt = lastTestedAt
        self.status = status
        self.fixedAt = fixedAt
        self.consecutivePasses = consecutivePasses
    }
}

// MARK: - Status Helpers

extension RegressionEntry {
    enum Status: String, Sendable {
        case stillFailing
        case fixed
        case regression
    }

    var statusEnum: Status {
        Status(rawValue: status) ?? .stillFailing
    }

    func updateStatus(to newStatus: Status) {
        status = newStatus.rawValue
    }
}
