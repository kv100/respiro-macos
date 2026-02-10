import Foundation

enum PracticeCatalog {
    static let all: [Practice] = [
        physiologicalSigh,
        boxBreathing,
        grounding54321,
        stopTechnique,
        selfCompassion,
    ]

    static let physiologicalSigh = Practice(
        id: "physiological-sigh",
        title: "Physiological Sigh",
        category: .breathing,
        duration: 60,
        steps: [
            PracticeStep(id: "ps-inhale1", instruction: "Quick inhale through nose", duration: 1),
            PracticeStep(id: "ps-hold", instruction: "Brief hold", duration: 0),
            PracticeStep(id: "ps-inhale2", instruction: "Second short inhale", duration: 1),
            PracticeStep(id: "ps-exhale", instruction: "Long exhale through mouth", duration: 4),
        ]
    )

    static let boxBreathing = Practice(
        id: "box-breathing",
        title: "Box Breathing",
        category: .breathing,
        duration: 90,
        steps: [
            PracticeStep(id: "bb-inhale", instruction: "Breathe in slowly", duration: 4),
            PracticeStep(id: "bb-hold1", instruction: "Hold your breath", duration: 4),
            PracticeStep(id: "bb-exhale", instruction: "Breathe out slowly", duration: 4),
            PracticeStep(id: "bb-hold2", instruction: "Hold before next breath", duration: 4),
        ]
    )

    static let grounding54321 = Practice(
        id: "grounding-54321",
        title: "5-4-3-2-1 Grounding",
        category: .body,
        duration: 120,
        steps: [
            PracticeStep(id: "g-see", instruction: "5 things you can see", duration: 30),
            PracticeStep(id: "g-hear", instruction: "4 things you can hear", duration: 25),
            PracticeStep(id: "g-touch", instruction: "3 things you can touch", duration: 25),
            PracticeStep(id: "g-smell", instruction: "2 things you can smell", duration: 20),
            PracticeStep(id: "g-taste", instruction: "1 thing you can taste", duration: 20),
        ]
    )

    static let stopTechnique = Practice(
        id: "stop-technique",
        title: "STOP Technique",
        category: .mind,
        duration: 60,
        steps: [
            PracticeStep(id: "st-stop", instruction: "Stop what you're doing", duration: 10),
            PracticeStep(id: "st-breath", instruction: "Take a deep breath", duration: 15),
            PracticeStep(id: "st-observe", instruction: "Observe your experience", duration: 20),
            PracticeStep(id: "st-proceed", instruction: "Proceed with awareness", duration: 15),
        ]
    )

    static let selfCompassion = Practice(
        id: "self-compassion",
        title: "Self-Compassion Break",
        category: .mind,
        duration: 90,
        steps: [
            PracticeStep(id: "sc-mindful", instruction: "Acknowledge what you're feeling", duration: 30),
            PracticeStep(id: "sc-humanity", instruction: "Connect with shared human experience", duration: 30),
            PracticeStep(id: "sc-kindness", instruction: "Offer yourself kindness", duration: 30),
        ]
    )

    static func practice(for id: String) -> Practice? {
        all.first { $0.id == id }
    }

    static func practiceType(for id: String) -> PracticeType? {
        PracticeType(rawValue: id)
    }
}
