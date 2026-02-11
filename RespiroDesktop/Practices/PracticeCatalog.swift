import Foundation

enum PracticeCatalog {
    static let all: [Practice] = [
        physiologicalSigh,
        boxBreathing,
        grounding54321,
        stopTechnique,
        selfCompassion,
        extendedExhale,
        thoughtDefusion,
        coherentBreathing,
        // V2
        fourSevenEight,
        bellyBreathing,
        alternateNostril,
        resonanceBreathing,
        bodyScan,
        progressiveRelaxation,
        gentleStretching,
        groundingFeet,
        lovingKindness,
        worryTime,
        mindfulListening,
        visualization,
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

    static let extendedExhale = Practice(
        id: "extended-exhale",
        title: "Extended Exhale",
        category: .breathing,
        duration: 90,
        steps: [
            PracticeStep(id: "ee-inhale", instruction: "Breathe in slowly", duration: 4),
            PracticeStep(id: "ee-exhale", instruction: "Long, slow exhale", duration: 6),
        ]
    )

    static let thoughtDefusion = Practice(
        id: "thought-defusion",
        title: "Thought Defusion",
        category: .mind,
        duration: 120,
        steps: [
            PracticeStep(id: "td-name", instruction: "Name the recurring thought", duration: 30),
            PracticeStep(id: "td-notice", instruction: "I notice I'm having the thought...", duration: 30),
            PracticeStep(id: "td-watch", instruction: "Watch the thought float by like a cloud", duration: 60),
        ]
    )

    static let coherentBreathing = Practice(
        id: "coherent-breathing",
        title: "Coherent Breathing",
        category: .breathing,
        duration: 120,
        steps: [
            PracticeStep(id: "cb-inhale", instruction: "Breathe in for 5 seconds", duration: 5),
            PracticeStep(id: "cb-exhale", instruction: "Breathe out for 5 seconds", duration: 5),
        ]
    )

    // MARK: - V2 Breathing

    static let fourSevenEight = Practice(
        id: "4-7-8-breathing",
        title: "4-7-8 Breathing",
        category: .breathing,
        duration: 120,
        steps: [
            PracticeStep(id: "478-inhale", instruction: "Inhale through your nose", duration: 4),
            PracticeStep(id: "478-hold", instruction: "Hold your breath", duration: 7),
            PracticeStep(id: "478-exhale", instruction: "Exhale through your mouth", duration: 8),
        ]
    )

    static let bellyBreathing = Practice(
        id: "belly-breathing",
        title: "Belly Breathing",
        category: .breathing,
        duration: 90,
        steps: [
            PracticeStep(id: "bb2-inhale", instruction: "Deep belly inhale", duration: 5),
            PracticeStep(id: "bb2-exhale", instruction: "Slow exhale", duration: 5),
        ]
    )

    static let alternateNostril = Practice(
        id: "alternate-nostril",
        title: "Alternate Nostril",
        category: .breathing,
        duration: 120,
        steps: [
            PracticeStep(id: "an-left-in", instruction: "Left nostril inhale", duration: 4),
            PracticeStep(id: "an-hold1", instruction: "Hold", duration: 2),
            PracticeStep(id: "an-right-out", instruction: "Right nostril exhale", duration: 4),
            PracticeStep(id: "an-right-in", instruction: "Right nostril inhale", duration: 4),
            PracticeStep(id: "an-hold2", instruction: "Hold", duration: 2),
            PracticeStep(id: "an-left-out", instruction: "Left nostril exhale", duration: 4),
        ]
    )

    static let resonanceBreathing = Practice(
        id: "resonance-breathing",
        title: "Resonance Breathing",
        category: .breathing,
        duration: 120,
        steps: [
            PracticeStep(id: "rb-inhale", instruction: "Breathe in slowly", duration: 6),
            PracticeStep(id: "rb-exhale", instruction: "Breathe out slowly", duration: 6),
        ]
    )

    // MARK: - V2 Body

    static let bodyScan = Practice(
        id: "body-scan",
        title: "Quick Body Scan",
        category: .body,
        duration: 120,
        steps: [
            PracticeStep(id: "bs-head", instruction: "Bring awareness to your head and face", duration: 20),
            PracticeStep(id: "bs-shoulders", instruction: "Notice your shoulders — let them drop", duration: 20),
            PracticeStep(id: "bs-chest", instruction: "Feel your chest rise and fall", duration: 20),
            PracticeStep(id: "bs-belly", instruction: "Soften your belly", duration: 20),
            PracticeStep(id: "bs-legs", instruction: "Scan down through your legs", duration: 20),
            PracticeStep(id: "bs-feet", instruction: "Feel your feet grounded on the floor", duration: 20),
        ]
    )

    static let progressiveRelaxation = Practice(
        id: "progressive-relaxation",
        title: "Progressive Relaxation",
        category: .body,
        duration: 120,
        steps: [
            PracticeStep(id: "pr-hands-tense", instruction: "Clench your fists tightly", duration: 15),
            PracticeStep(id: "pr-hands-release", instruction: "Release — feel the warmth flow in", duration: 15),
            PracticeStep(id: "pr-shoulders-tense", instruction: "Raise shoulders to your ears", duration: 15),
            PracticeStep(id: "pr-shoulders-release", instruction: "Drop them — let tension melt away", duration: 15),
            PracticeStep(id: "pr-face-tense", instruction: "Scrunch your face muscles", duration: 15),
            PracticeStep(id: "pr-face-release", instruction: "Relax — smooth out every muscle", duration: 15),
            PracticeStep(id: "pr-body-tense", instruction: "Tense your whole body at once", duration: 15),
            PracticeStep(id: "pr-body-release", instruction: "Release everything — total relaxation", duration: 15),
        ]
    )

    static let gentleStretching = Practice(
        id: "gentle-stretching",
        title: "Desk Stretch",
        category: .body,
        duration: 90,
        steps: [
            PracticeStep(id: "gs-neck", instruction: "Slowly roll your neck in circles", duration: 20),
            PracticeStep(id: "gs-shoulders", instruction: "Shrug shoulders up, hold, release", duration: 20),
            PracticeStep(id: "gs-wrists", instruction: "Circle your wrists gently", duration: 15),
            PracticeStep(id: "gs-twist", instruction: "Seated spinal twist — each side", duration: 20),
            PracticeStep(id: "gs-fold", instruction: "Gentle forward fold from your chair", duration: 15),
        ]
    )

    static let groundingFeet = Practice(
        id: "grounding-feet",
        title: "Feet Grounding",
        category: .body,
        duration: 60,
        steps: [
            PracticeStep(id: "gf-feel", instruction: "Feel both feet flat on the floor", duration: 15),
            PracticeStep(id: "gf-toes", instruction: "Press your toes down firmly", duration: 15),
            PracticeStep(id: "gf-heels", instruction: "Rock gently onto your heels", duration: 15),
            PracticeStep(id: "gf-still", instruction: "Stand still — feel rooted", duration: 15),
        ]
    )

    // MARK: - V2 Mind

    static let lovingKindness = Practice(
        id: "loving-kindness",
        title: "Loving Kindness",
        category: .mind,
        duration: 120,
        steps: [
            PracticeStep(id: "lk-self", instruction: "May I be happy, may I be well", duration: 30),
            PracticeStep(id: "lk-loved", instruction: "Send warmth to someone you love", duration: 30),
            PracticeStep(id: "lk-neutral", instruction: "Extend kindness to a neutral person", duration: 30),
            PracticeStep(id: "lk-all", instruction: "Radiate compassion to all beings", duration: 30),
        ]
    )

    static let worryTime = Practice(
        id: "worry-time",
        title: "Worry Time Box",
        category: .mind,
        duration: 90,
        steps: [
            PracticeStep(id: "wt-list", instruction: "Mentally list your current worries", duration: 30),
            PracticeStep(id: "wt-sort", instruction: "Sort: what can I control vs. not?", duration: 20),
            PracticeStep(id: "wt-release", instruction: "Consciously let go of what you can't control", duration: 20),
            PracticeStep(id: "wt-present", instruction: "Return your attention to the present", duration: 20),
        ]
    )

    static let mindfulListening = Practice(
        id: "mindful-listening",
        title: "Mindful Listening",
        category: .mind,
        duration: 60,
        steps: [
            PracticeStep(id: "ml-notice", instruction: "Notice all the sounds around you", duration: 20),
            PracticeStep(id: "ml-focus", instruction: "Focus on just one sound", duration: 20),
            PracticeStep(id: "ml-expand", instruction: "Expand awareness to all sounds again", duration: 20),
        ]
    )

    static let visualization = Practice(
        id: "visualization",
        title: "Safe Place",
        category: .mind,
        duration: 120,
        steps: [
            PracticeStep(id: "vis-imagine", instruction: "Picture a place where you feel completely safe", duration: 30),
            PracticeStep(id: "vis-details", instruction: "Notice the colors, textures, light", duration: 30),
            PracticeStep(id: "vis-warmth", instruction: "Feel the warmth and safety of this place", duration: 30),
            PracticeStep(id: "vis-anchor", instruction: "Anchor this feeling — you can return anytime", duration: 30),
        ]
    )

    static func practice(for id: String) -> Practice? {
        all.first { $0.id == id }
    }

    static func practiceType(for id: String) -> PracticeType? {
        PracticeType(rawValue: id)
    }
}
