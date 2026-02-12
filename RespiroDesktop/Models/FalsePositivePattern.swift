import Foundation
import SwiftData

/// Tracks contexts where nudges were consistently dismissed (false positives).
/// Used to suppress future nudges in similar situations.
@Model
final class FalsePositivePattern {
    var context: String
    var dismissalCount: Int
    var avgConfidence: Double
    var lastOccurred: Date

    init(context: String) {
        self.context = context
        self.dismissalCount = 0
        self.avgConfidence = 0.0
        self.lastOccurred = Date()
    }
}
