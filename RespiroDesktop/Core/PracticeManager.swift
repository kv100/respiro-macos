import SwiftUI

enum BreathPhase: String, Sendable {
    case idle
    case inhale = "INHALE"
    case hold = "HOLD"
    case exhale = "EXHALE"

    var label: String { rawValue }
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

    func startPractice() {
        isActive = true
        isPaused = false
        currentPhase = .idle
        completedCycles = 0
        totalCycles = 10
        remainingSeconds = 60
        totalDuration = 60

        practiceTask?.cancel()
        practiceTask = Task { [weak self] in
            guard let self else { return }
            await self.runPhysiologicalSigh()
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
            await self.runPhysiologicalSigh()
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

    // MARK: - Physiological Sigh Pattern

    // Double-inhale (2s) + long-exhale (4s) x 10 cycles = 60s
    // Double-inhale: quick inhale(1s) + short hold(0.3s) + second inhale(0.7s)
    private func runPhysiologicalSigh() async {
        let startCycle = completedCycles

        for cycle in startCycle..<totalCycles {
            guard !Task.isCancelled else { return }

            // Phase 1: First inhale (1.0s)
            currentPhase = .inhale
            phaseDuration = 1.0
            if await sleepPhase(seconds: 1.0) { return }

            // Phase 2: Short hold (0.3s)
            currentPhase = .hold
            phaseDuration = 0.3
            if await sleepPhase(seconds: 0.3) { return }

            // Phase 3: Second inhale (0.7s)
            currentPhase = .inhale
            phaseDuration = 0.7
            if await sleepPhase(seconds: 0.7) { return }

            // Phase 4: Long exhale (4.0s)
            currentPhase = .exhale
            phaseDuration = 4.0
            if await sleepPhase(seconds: 4.0) { return }

            completedCycles = cycle + 1
            remainingSeconds = max(0, totalDuration - (completedCycles * 6))
        }

        // Practice complete
        completePractice()
    }

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
                let elapsed = totalDuration - remainingSeconds + 1
                remainingSeconds = max(0, totalDuration - elapsed)
            }
        }
        return Task.isCancelled
    }
}
