import Foundation

// MARK: - NudgeDecision

struct NudgeDecision: Sendable {
    let shouldShow: Bool
    let nudgeType: NudgeType?
    let message: String?
    let suggestedPracticeID: String?
    let reason: String
}

// MARK: - NudgeEngine

actor NudgeEngine {

    // MARK: - Cooldown Constants

    private enum Cooldown {
        static let minPracticeInterval: TimeInterval = 30 * 60        // 30 min between practice nudges
        static let minAnyNudgeInterval: TimeInterval = 10 * 60        // 10 min between any nudge
        static let postDismissalCooldown: TimeInterval = 15 * 60      // 15 min after dismissal
        static let consecutiveDismissalCooldown: TimeInterval = 2 * 3600  // 2h after 3 dismissals
        static let postPracticeCooldown: TimeInterval = 45 * 60       // 45 min after practice
        static let hardMinInterval: TimeInterval = 5 * 60             // NEVER nudge within 5 min
        static let maxDailyPracticeNudges: Int = 6
        static let maxDailyTotalNudges: Int = 12
    }

    // MARK: - State

    private var lastNudgeTime: Date?
    private var lastPracticeNudgeTime: Date?
    private var lastPracticeCompletedTime: Date?
    private var consecutiveDismissals: Int = 0
    private var lastDismissalTime: Date?
    private var dailyNudgeCount: Int = 0
    private var dailyPracticeNudgeCount: Int = 0
    private var dailyResetDate: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - Smart Suppression

    private var pendingDelay: (until: Date, reason: String)?

    /// Check suppression result from SmartSuppression (called from @MainActor before shouldNudge)
    nonisolated func evaluateSuppression(_ result: SuppressionResult) -> NudgeDecision? {
        switch result {
        case .allowed:
            return nil
        case .neverNow(let reason):
            return NudgeDecision(
                shouldShow: false, nudgeType: nil, message: nil,
                suggestedPracticeID: nil, reason: "suppressed_\(reason)"
            )
        case .delayFor(_, let reason):
            return NudgeDecision(
                shouldShow: false, nudgeType: nil, message: nil,
                suggestedPracticeID: nil, reason: "delayed_\(reason)"
            )
        }
    }

    // MARK: - Main Decision Logic

    func shouldNudge(for analysis: StressAnalysisResponse) -> NudgeDecision {
        resetDailyCountersIfNeeded()

        let now = Date()

        // 1. AI says don't nudge
        guard let nudgeTypeRaw = analysis.nudgeType,
              let nudgeType = NudgeType(rawValue: nudgeTypeRaw) else {
            return NudgeDecision(
                shouldShow: false, nudgeType: nil, message: nil,
                suggestedPracticeID: nil, reason: "ai_no_nudge"
            )
        }

        // 2. Hard 5-min minimum between any nudges
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval")
        }

        // 3. Daily total limit
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit")
        }

        // 4. Daily practice nudge limit
        if nudgeType == .practice && dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            return denied(reason: "daily_practice_limit")
        }

        // 5. Min interval between any nudge (10 min)
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval")
        }

        // 6. Min interval between practice nudges (30 min)
        if nudgeType == .practice,
           let last = lastPracticeNudgeTime,
           now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            return denied(reason: "min_practice_interval")
        }

        // 7. Post-practice cooldown (45 min)
        if let last = lastPracticeCompletedTime,
           now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            return denied(reason: "post_practice_cooldown")
        }

        // 8. Post-dismissal cooldown
        if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3
                ? Cooldown.consecutiveDismissalCooldown
                : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                return denied(reason: consecutiveDismissals >= 3
                    ? "consecutive_dismissal_cooldown"
                    : "post_dismissal_cooldown")
            }
        }

        // All checks passed
        return NudgeDecision(
            shouldShow: true,
            nudgeType: nudgeType,
            message: analysis.nudgeMessage,
            suggestedPracticeID: analysis.suggestedPracticeID,
            reason: "approved"
        )
    }

    // MARK: - Event Recording

    func recordNudgeShown(type: NudgeType) {
        let now = Date()
        lastNudgeTime = now
        dailyNudgeCount += 1

        if type == .practice {
            lastPracticeNudgeTime = now
            dailyPracticeNudgeCount += 1
        }

        // Showing a nudge resets consecutive dismissals
        // (they get incremented again if user dismisses)
    }

    func recordDismissal() {
        consecutiveDismissals += 1
        lastDismissalTime = Date()
    }

    func recordPracticeCompleted() {
        lastPracticeCompletedTime = Date()
        consecutiveDismissals = 0
    }

    // MARK: - Read-only Accessors

    var currentConsecutiveDismissals: Int {
        consecutiveDismissals
    }

    var todayNudgeCount: Int {
        resetDailyCountersIfNeeded()
        return dailyNudgeCount
    }

    // MARK: - Private

    @discardableResult
    private func resetDailyCountersIfNeeded() -> Bool {
        let todayStart = Calendar.current.startOfDay(for: Date())
        if todayStart > dailyResetDate {
            dailyResetDate = todayStart
            dailyNudgeCount = 0
            dailyPracticeNudgeCount = 0
            return true
        }
        return false
    }

    private func denied(reason: String) -> NudgeDecision {
        NudgeDecision(
            shouldShow: false, nudgeType: nil, message: nil,
            suggestedPracticeID: nil, reason: reason
        )
    }
}
