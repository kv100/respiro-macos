import SwiftUI

enum BreathPhase: String, Sendable {
    case idle
    case inhale = "INHALE"
    case hold = "HOLD"
    case exhale = "EXHALE"

    var label: String { rawValue }
}

enum PracticeType: String, Sendable {
    case physiologicalSigh = "physiological-sigh"
    case boxBreathing = "box-breathing"
    case grounding = "grounding-54321"
    case stopTechnique = "stop-technique"
    case selfCompassion = "self-compassion"
    case extendedExhale = "extended-exhale"
    case thoughtDefusion = "thought-defusion"
    case coherentBreathing = "coherent-breathing"
    // V2: Breathing
    case fourSevenEight = "4-7-8-breathing"
    case bellyBreathing = "belly-breathing"
    case alternateNostril = "alternate-nostril"
    case resonanceBreathing = "resonance-breathing"
    // V2: Body
    case bodyScan = "body-scan"
    case progressiveRelaxation = "progressive-relaxation"
    case gentleStretching = "gentle-stretching"
    case groundingFeet = "grounding-feet"
    // V2: Mind
    case lovingKindness = "loving-kindness"
    case worryTime = "worry-time"
    case mindfulListening = "mindful-listening"
    case visualization = "visualization"
}

// MARK: - Grounding

enum GroundingSense: String, Sendable {
    case see = "SEE"
    case hear = "HEAR"
    case touch = "TOUCH"
    case smell = "SMELL"
    case taste = "TASTE"

    var icon: String {
        switch self {
        case .see: return "eye"
        case .hear: return "ear"
        case .touch: return "hand.raised"
        case .smell: return "nose"
        case .taste: return "mouth"
        }
    }

    var count: Int {
        switch self {
        case .see: return 5
        case .hear: return 4
        case .touch: return 3
        case .smell: return 2
        case .taste: return 1
        }
    }

    var prompt: String {
        switch self {
        case .see: return "things you can see"
        case .hear: return "things you can hear"
        case .touch: return "things you can touch"
        case .smell: return "things you can smell"
        case .taste: return "thing you can taste"
        }
    }
}

// MARK: - STOP Technique

enum STOPPhase: String, Sendable {
    case stop = "S"
    case takeABreath = "T"
    case observe = "O"
    case proceed = "P"

    var title: String {
        switch self {
        case .stop: return "Stop"
        case .takeABreath: return "Take a Breath"
        case .observe: return "Observe"
        case .proceed: return "Proceed"
        }
    }

    var instruction: String {
        switch self {
        case .stop: return "Pause whatever you're doing.\nLet yourself be still for a moment."
        case .takeABreath: return "Take a slow, deep breath.\nFeel the air fill your lungs,\nthen gently exhale."
        case .observe: return "Notice what you're experiencing.\nWhat thoughts are present?\nWhat sensations do you feel?"
        case .proceed: return "Continue with awareness.\nCarry this clarity forward\ninto your next action."
        }
    }

    var duration: Double {
        switch self {
        case .stop: return 10
        case .takeABreath: return 15
        case .observe: return 20
        case .proceed: return 15
        }
    }
}

// MARK: - Self-Compassion

enum CompassionPhase: String, Sendable {
    case mindfulness
    case commonHumanity = "common-humanity"
    case kindness

    var title: String {
        switch self {
        case .mindfulness: return "Mindfulness"
        case .commonHumanity: return "Common Humanity"
        case .kindness: return "Kindness"
        }
    }

    var instruction: String {
        switch self {
        case .mindfulness: return "This is a moment of difficulty.\nAcknowledge what you're feeling\nwithout judgment or resistance."
        case .commonHumanity: return "Difficulty is part of being human.\nEveryone struggles sometimes.\nYou are not alone in this."
        case .kindness: return "May I be kind to myself.\nMay I give myself the compassion\nI would offer a good friend."
        }
    }

    var duration: Double { 30 }
}

// MARK: - Thought Defusion

enum DefusionPhase: String, Sendable {
    case nameThought = "name"
    case noticeThought = "notice"
    case watchItPass = "watch"

    var title: String {
        switch self {
        case .nameThought: return "Name the Thought"
        case .noticeThought: return "Notice the Thought"
        case .watchItPass: return "Watch It Pass"
        }
    }

    var instruction: String {
        switch self {
        case .nameThought: return "What thought keeps returning?\nGive it a simple name.\n\"Worry about deadline\" or \"Self-doubt.\""
        case .noticeThought: return "Say to yourself:\n\"I notice I'm having the thought\nthat...\" and complete the sentence."
        case .watchItPass: return "Imagine this thought as a cloud\nfloating across the sky.\nWatch it drift by, without holding on."
        }
    }

    var shortLabel: String {
        switch self {
        case .nameThought: return "Name"
        case .noticeThought: return "Notice"
        case .watchItPass: return "Watch"
        }
    }

    var duration: Double {
        switch self {
        case .nameThought: return 30
        case .noticeThought: return 30
        case .watchItPass: return 60
        }
    }
}

@MainActor
@Observable
final class PracticeManager {
    // MARK: - State

    var isActive: Bool = false
    var isPaused: Bool = false
    var currentPhase: BreathPhase = .idle
    var phaseDuration: Double = 0
    var completedCycles: Int = 0
    var totalCycles: Int = 10
    var remainingSeconds: Int = 60
    var totalDuration: Int = 60
    var practiceType: PracticeType = .physiologicalSigh

    // Grounding state
    var currentSense: GroundingSense = .see
    var currentSenseItemsDone: Int = 0
    var totalGroundingItems: Int = 15
    var completedGroundingItems: Int = 0

    // STOP state
    var currentSTOPPhase: STOPPhase = .stop

    // Self-Compassion state
    var currentCompassionPhase: CompassionPhase = .mindfulness

    // Thought Defusion state
    var currentDefusionPhase: DefusionPhase = .nameThought

    // Generic step-based practice state (V2)
    var currentGenericStep: Int = 0
    var currentStepInstruction: String = ""

    // MARK: - Private

    private var practiceTask: Task<Void, Never>?

    // MARK: - Computed

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return Double(totalDuration - remainingSeconds) / Double(totalDuration)
    }

    var remainingFormatted: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Actions

    func startPractice(type: PracticeType = .physiologicalSigh) {
        practiceType = type
        isActive = true
        isPaused = false
        currentPhase = .idle
        completedCycles = 0

        switch type {
        case .physiologicalSigh:
            totalCycles = 10
            totalDuration = 60
        case .boxBreathing:
            totalCycles = 5
            totalDuration = 90  // 5 cycles x (4+4+4+4)s = 80s + buffer ≈ 90s
        case .grounding:
            totalDuration = 120
            currentSense = .see
            currentSenseItemsDone = 0
            completedGroundingItems = 0
            totalGroundingItems = 15
        case .stopTechnique:
            totalDuration = 60
            currentSTOPPhase = .stop
        case .selfCompassion:
            totalDuration = 90
            currentCompassionPhase = .mindfulness
        case .extendedExhale:
            totalCycles = 9
            totalDuration = 90  // 9 cycles x (4+6)s = 90s
        case .thoughtDefusion:
            totalDuration = 120
            currentDefusionPhase = .nameThought
        case .coherentBreathing:
            totalCycles = 12
            totalDuration = 120  // 12 cycles x (5+5)s = 120s
        // V2: Breathing
        case .fourSevenEight:
            totalCycles = 6
            totalDuration = 120  // 6 cycles x (4+7+8)s = 114s + buffer
        case .bellyBreathing:
            totalCycles = 9
            totalDuration = 90   // 9 cycles x (5+5)s = 90s
        case .alternateNostril:
            totalCycles = 6
            totalDuration = 120  // 6 cycles x (4+2+4+4+2+4)s = 120s
        case .resonanceBreathing:
            totalCycles = 10
            totalDuration = 120  // 10 cycles x (6+6)s = 120s
        // V2: Body (step-based)
        case .bodyScan:
            totalDuration = 120
            currentGenericStep = 0
        case .progressiveRelaxation:
            totalDuration = 120
            currentGenericStep = 0
        case .gentleStretching:
            totalDuration = 90
            currentGenericStep = 0
        case .groundingFeet:
            totalDuration = 60
            currentGenericStep = 0
        // V2: Mind (step-based)
        case .lovingKindness:
            totalDuration = 120
            currentGenericStep = 0
        case .worryTime:
            totalDuration = 90
            currentGenericStep = 0
        case .mindfulListening:
            totalDuration = 60
            currentGenericStep = 0
        case .visualization:
            totalDuration = 120
            currentGenericStep = 0
        }

        remainingSeconds = totalDuration

        practiceTask?.cancel()
        practiceTask = Task { [weak self] in
            guard let self else { return }
            await self.runPractice()
        }
    }

    func pausePractice() {
        isPaused = true
        practiceTask?.cancel()
    }

    func resumePractice() {
        isPaused = false
        practiceTask?.cancel()
        practiceTask = Task { [weak self] in
            guard let self else { return }
            await self.runPractice()
        }
    }

    func stopPractice() {
        practiceTask?.cancel()
        practiceTask = nil
        isActive = false
        isPaused = false
        currentPhase = .idle
        completedCycles = 0
        remainingSeconds = 0
    }

    func completePractice() {
        practiceTask?.cancel()
        practiceTask = nil
        isActive = false
        isPaused = false
        currentPhase = .idle
    }

    // Grounding: user taps to confirm an item
    func confirmGroundingItem() {
        currentSenseItemsDone += 1
        completedGroundingItems += 1

        if currentSenseItemsDone >= currentSense.count {
            // Move to next sense
            switch currentSense {
            case .see: currentSense = .hear
            case .hear: currentSense = .touch
            case .touch: currentSense = .smell
            case .smell: currentSense = .taste
            case .taste:
                // All done
                completePractice()
                return
            }
            currentSenseItemsDone = 0
        }
    }

    // MARK: - Phase Transition

    private func setPhase(_ phase: BreathPhase, duration: Double) {
        let previousPhase = currentPhase
        currentPhase = phase
        phaseDuration = duration
        // Play subtle sound on phase transitions (not on first phase from idle)
        if previousPhase != .idle && previousPhase != phase {
            SoundService.shared.playPhaseChange()
        }
    }

    // MARK: - Practice Router

    private func runPractice() async {
        switch practiceType {
        case .physiologicalSigh:
            await runPhysiologicalSigh()
        case .boxBreathing:
            await runBoxBreathing()
        case .grounding:
            await runGrounding()
        case .stopTechnique:
            await runSTOPTechnique()
        case .selfCompassion:
            await runSelfCompassion()
        case .extendedExhale:
            await runExtendedExhale()
        case .thoughtDefusion:
            await runThoughtDefusion()
        case .coherentBreathing:
            await runCoherentBreathing()
        // V2: Breathing
        case .fourSevenEight:
            await runFourSevenEight()
        case .bellyBreathing:
            await runBellyBreathing()
        case .alternateNostril:
            await runAlternateNostril()
        case .resonanceBreathing:
            await runResonanceBreathing()
        // V2: Step-based (body + mind)
        case .bodyScan, .progressiveRelaxation, .gentleStretching, .groundingFeet,
             .lovingKindness, .worryTime, .mindfulListening, .visualization:
            await runGenericStepPractice()
        }
    }

    // MARK: - Physiological Sigh Pattern

    // Double-inhale (2s) + long-exhale (4s) x 10 cycles = 60s
    private func runPhysiologicalSigh() async {
        let startCycle = completedCycles

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            // Phase 1: First inhale (1.0s)
            setPhase(.inhale, duration: 1.0)
            if await sleepPhase(seconds: 1.0) { return }

            // Phase 2: Short hold (0.3s)
            setPhase(.hold, duration: 0.3)
            if await sleepPhase(seconds: 0.3) { return }

            // Phase 3: Second inhale (0.7s)
            setPhase(.inhale, duration: 0.7)
            if await sleepPhase(seconds: 0.7) { return }

            // Phase 4: Long exhale (4.0s)
            setPhase(.exhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * 6))
        }

        completePractice()
    }

    // MARK: - Box Breathing Pattern

    // inhale(4s) + hold(4s) + exhale(4s) + hold(4s) x 5 = 80s
    private func runBoxBreathing() async {
        let startCycle = completedCycles
        let cycleLength = 16 // 4+4+4+4

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            // Phase 1: Inhale (4s)
            setPhase(.inhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            // Phase 2: Hold (4s)
            setPhase(.hold, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            // Phase 3: Exhale (4s)
            setPhase(.exhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            // Phase 4: Hold (4s)
            setPhase(.hold, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Grounding (timer only, interactions handled by view)

    private func runGrounding() async {
        // Tick down the timer; actual progression is driven by user taps
        while remainingSeconds > 0 && !Task.isCancelled && isActive {
            if await sleepPhase(seconds: 1.0) { return }
            remainingSeconds = max(0, remainingSeconds - 1)
        }

        if remainingSeconds <= 0 {
            completePractice()
        }
    }

    // MARK: - STOP Technique

    private func runSTOPTechnique() async {
        let phases: [STOPPhase] = [.stop, .takeABreath, .observe, .proceed]

        for phase in phases {
            guard !Task.isCancelled else { return }

            currentSTOPPhase = phase
            let duration = phase.duration
            if await sleepPhase(seconds: duration) { return }
            remainingSeconds = max(0, remainingSeconds - Int(duration))
        }

        completePractice()
    }

    // MARK: - Self-Compassion

    private func runSelfCompassion() async {
        let phases: [CompassionPhase] = [.mindfulness, .commonHumanity, .kindness]

        for phase in phases {
            guard !Task.isCancelled else { return }

            currentCompassionPhase = phase
            let duration = phase.duration
            if await sleepPhase(seconds: duration) { return }
            remainingSeconds = max(0, remainingSeconds - Int(duration))
        }

        completePractice()
    }

    // MARK: - Extended Exhale Pattern

    // inhale(4s) + exhale(6s) x 9 = 90s
    private func runExtendedExhale() async {
        let startCycle = completedCycles
        let cycleLength = 10 // 4+6

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            // Phase 1: Inhale (4s)
            setPhase(.inhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            // Phase 2: Long exhale (6s)
            setPhase(.exhale, duration: 6.0)
            if await sleepPhase(seconds: 6.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Thought Defusion

    private func runThoughtDefusion() async {
        let phases: [DefusionPhase] = [.nameThought, .noticeThought, .watchItPass]

        for phase in phases {
            guard !Task.isCancelled else { return }

            currentDefusionPhase = phase
            let duration = phase.duration
            if await sleepPhase(seconds: duration) { return }
            remainingSeconds = max(0, remainingSeconds - Int(duration))
        }

        completePractice()
    }

    // MARK: - Coherent Breathing Pattern

    // inhale(5s) + exhale(5s) x 12 = 120s
    private func runCoherentBreathing() async {
        let startCycle = completedCycles
        let cycleLength = 10 // 5+5

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            // Phase 1: Inhale (5s)
            setPhase(.inhale, duration: 5.0)
            if await sleepPhase(seconds: 5.0) { return }

            // Phase 2: Exhale (5s)
            setPhase(.exhale, duration: 5.0)
            if await sleepPhase(seconds: 5.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - 4-7-8 Breathing Pattern

    // inhale(4s) + hold(7s) + exhale(8s) x 6 = 114s
    private func runFourSevenEight() async {
        let startCycle = completedCycles
        let cycleLength = 19 // 4+7+8

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            setPhase(.inhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            setPhase(.hold, duration: 7.0)
            if await sleepPhase(seconds: 7.0) { return }

            setPhase(.exhale, duration: 8.0)
            if await sleepPhase(seconds: 8.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Belly Breathing Pattern

    // inhale(5s) + exhale(5s) x 9 = 90s
    private func runBellyBreathing() async {
        let startCycle = completedCycles
        let cycleLength = 10 // 5+5

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            setPhase(.inhale, duration: 5.0)
            if await sleepPhase(seconds: 5.0) { return }

            setPhase(.exhale, duration: 5.0)
            if await sleepPhase(seconds: 5.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Alternate Nostril Pattern

    // left inhale(4s) + hold(2s) + right exhale(4s) + right inhale(4s) + hold(2s) + left exhale(4s) x 6 = 120s
    private func runAlternateNostril() async {
        let startCycle = completedCycles
        let cycleLength = 20 // 4+2+4+4+2+4

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            currentStepInstruction = "Left nostril inhale"
            setPhase(.inhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            setPhase(.hold, duration: 2.0)
            if await sleepPhase(seconds: 2.0) { return }

            currentStepInstruction = "Right nostril exhale"
            setPhase(.exhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            currentStepInstruction = "Right nostril inhale"
            setPhase(.inhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            setPhase(.hold, duration: 2.0)
            if await sleepPhase(seconds: 2.0) { return }

            currentStepInstruction = "Left nostril exhale"
            setPhase(.exhale, duration: 4.0)
            if await sleepPhase(seconds: 4.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Resonance Breathing Pattern

    // inhale(6s) + exhale(6s) x 10 = 120s
    private func runResonanceBreathing() async {
        let startCycle = completedCycles
        let cycleLength = 12 // 6+6

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            setPhase(.inhale, duration: 6.0)
            if await sleepPhase(seconds: 6.0) { return }

            setPhase(.exhale, duration: 6.0)
            if await sleepPhase(seconds: 6.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * cycleLength))
        }

        completePractice()
    }

    // MARK: - Generic Step-Based Practice

    private func runGenericStepPractice() async {
        guard let practice = PracticeCatalog.practice(for: practiceType.rawValue) else {
            completePractice()
            return
        }

        let steps = practice.steps
        for (index, step) in steps.enumerated() {
            guard !Task.isCancelled else { return }

            currentGenericStep = index
            currentStepInstruction = step.instruction
            let duration = Double(step.duration)
            if await sleepPhase(seconds: duration) { return }
            remainingSeconds = max(0, remainingSeconds - step.duration)
        }

        completePractice()
    }

    // MARK: - Sleep Utility

    /// Sleep for a given duration, ticking down remainingSeconds.
    /// Returns true if cancelled.
    private func sleepPhase(seconds: Double) async -> Bool {
        let intervalMs: UInt64 = 100
        let ticks = Int(seconds * 10)

        for tick in 0..<ticks {
            guard !Task.isCancelled else { return true }
            try? await Task.sleep(nanoseconds: intervalMs * 1_000_000)

            // Update remaining seconds every full second
            if tick > 0 && tick % 10 == 0 {
                remainingSeconds = max(0, remainingSeconds - 1)
            }
        }
        return Task.isCancelled
    }
}
