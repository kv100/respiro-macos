import Foundation

struct PracticeStep: Sendable {
    let id: String
    let instruction: String
    let duration: Int
}

enum PracticeCategory: String, Sendable {
    case breathing
    case body
    case mind
}

struct Practice: Identifiable, Sendable {
    let id: String
    let title: String
    let category: PracticeCategory
    let duration: Int
    let steps: [PracticeStep]
}
