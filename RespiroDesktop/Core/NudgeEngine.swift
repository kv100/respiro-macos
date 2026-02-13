import Foundation

// MARK: - NudgeDecision

struct NudgeDecision: Sendable {
    let shouldShow: Bool
    let nudgeType: NudgeType?
    let message: String?
    let suggestedPracticeID: String?
    let reason: String
    let thinkingText: String?
    let effortLevel: EffortLevel?

    init(shouldShow: Bool, nudgeType: NudgeType?, message: String?,
         suggestedPracticeID: String?, reason: String, thinkingText: String? = nil, effortLevel: EffortLevel? = nil) {
        self.shouldShow = shouldShow
        self.nudgeType = nudgeType
        self.message = message
        self.suggestedPracticeID = suggestedPracticeID
        self.reason = reason
        self.thinkingText = thinkingText
        self.effortLevel = effortLevel
    }
}

// MARK: - BehavioralContext

/// Behavioral context for nudge decisions — rule-based override layer
struct BehavioralContext: Sendable {
    let metrics: BehaviorMetrics
    let baselineDeviation: Double
    let systemContext: SystemContext?

    /// Calculate behavioral severity score (0.0 - 1.0)
    static func severity(_ context: BehavioralContext?) -> Double {
        guard let ctx = context else { return 0.5 }
        var score = 0.0
        let switches = ctx.metrics.contextSwitchesPerMinute
        if switches > 8 { score += 0.4 }
        else if switches > 5 { score += 0.3 }
        else if switches > 3 { score += 0.15 }
        let deviation = ctx.baselineDeviation
        if deviation > 2.5 { score += 0.4 }
        else if deviation > 1.5 { score += 0.3 }
        else if deviation > 0.5 { score += 0.15 }
        if ctx.metrics.sessionDuration > 3 * 3600 { score += 0.1 }
        else if ctx.metrics.sessionDuration > 2 * 3600 { score += 0.05 }
        if let maxFocus = ctx.metrics.applicationFocus.values.max(), maxFocus < 0.3 {
            score += 0.1
        }
        return min(1.0, score)
    }
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
    private var clockOffset: TimeInterval = 0

    // MARK: - False Positive Tracking

    private var dismissalContexts: [(context: String, confidence: Double, timestamp: Date)] = []

    private var now: Date { Date().addingTimeInterval(clockOffset) }

    func advanceTime(by interval: TimeInterval) {
        clockOffset += interval
    }

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

    func shouldNudge(for analysis: StressAnalysisResponse, behavioral: BehavioralContext? = nil) -> NudgeDecision {
        resetDailyCountersIfNeeded()

        let now = self.now

        // 0. Smart suppression: video call active
        if let ctx = behavioral?.systemContext, ctx.isOnVideoCall {
            return denied(reason: "smart_suppression_video_call")
        }

        // 1. Calculate behavioral severity
        let severity = BehavioralContext.severity(behavioral)

        // 2. AI says don't nudge — check behavioral override
        guard let nudgeTypeRaw = analysis.nudgeType,
              let nudgeType = NudgeType(rawValue: nudgeTypeRaw) else {
            // Behavioral override: extreme distress forces nudge
            if severity >= 0.7 {
                return applyCooldowns(analysis: analysis, now: now, reason: "behavioral_override")
            }
            return NudgeDecision(
                shouldShow: false, nudgeType: nil, message: nil,
                suggestedPracticeID: nil, reason: "ai_no_nudge"
            )
        }

        // 3. Behavioral contradiction: AI says nudge but behavior is calm
        if severity < 0.15 && analysis.weather == "stormy" {
            return denied(reason: "behavioral_contradiction")
        }

        // 4. Hard 5-min minimum between any nudges
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval")
        }

        // 5. Daily total limit
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit")
        }

        // 6. Daily practice nudge limit
        if nudgeType == .practice && dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            return denied(reason: "daily_practice_limit")
        }

        // 7. Min interval between any nudge (10 min)
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval")
        }

        // 8. Min interval between practice nudges (30 min)
        if nudgeType == .practice,
           let last = lastPracticeNudgeTime,
           now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            return denied(reason: "min_practice_interval")
        }

        // 9. Post-practice cooldown (45 min)
        if let last = lastPracticeCompletedTime,
           now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            return denied(reason: "post_practice_cooldown")
        }

        // 10. Post-dismissal cooldown
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
            reason: "approved",
            thinkingText: analysis.thinkingText,
            effortLevel: analysis.effortLevel
        )
    }

    /// Apply cooldown checks for behavioral override nudges
    private func applyCooldowns(analysis: StressAnalysisResponse, now: Date, reason: String) -> NudgeDecision {
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval")
        }
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit")
        }
        if dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            return denied(reason: "daily_practice_limit")
        }
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval")
        }
        if let last = lastPracticeNudgeTime, now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            return denied(reason: "min_practice_interval")
        }
        if let last = lastPracticeCompletedTime, now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            return denied(reason: "post_practice_cooldown")
        }
        if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3 ? Cooldown.consecutiveDismissalCooldown : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                return denied(reason: consecutiveDismissals >= 3 ? "consecutive_dismissal_cooldown" : "post_dismissal_cooldown")
            }
        }
        return NudgeDecision(
            shouldShow: true,
            nudgeType: .practice,
            message: analysis.nudgeMessage ?? "Your activity patterns suggest elevated stress. A quick practice might help.",
            suggestedPracticeID: analysis.suggestedPracticeID ?? "box-breathing",
            reason: reason,
            thinkingText: analysis.thinkingText,
            effortLevel: analysis.effortLevel
        )
    }

    // MARK: - Event Recording

    func recordNudgeShown(type: NudgeType) {
        let now = self.now
        lastNudgeTime = now
        dailyNudgeCount += 1

        if type == .practice {
            lastPracticeNudgeTime = now
            dailyPracticeNudgeCount += 1
        }

        // Note: consecutiveDismissals is NOT reset here — only reset when practice is completed.
        // Counter tracks dismissals-in-a-row without completing any practice.
    }

    func recordDismissal() {
        consecutiveDismissals += 1
        lastDismissalTime = now
    }

    func recordPracticeCompleted() {
        lastPracticeCompletedTime = now
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

    func cooldownSnapshot() -> PlaytestResult.CooldownSnapshot {
        let now = self.now
        var isInCooldown = false
        var cooldownReason: String?

        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            isInCooldown = true
            cooldownReason = "hard_min_interval"
        } else if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            isInCooldown = true
            cooldownReason = "min_nudge_interval"
        } else if let last = lastPracticeCompletedTime, now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            isInCooldown = true
            cooldownReason = "post_practice_cooldown"
        } else if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3
                ? Cooldown.consecutiveDismissalCooldown
                : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                isInCooldown = true
                cooldownReason = consecutiveDismissals >= 3 ? "consecutive_dismissal_cooldown" : "post_dismissal_cooldown"
            }
        }

        return PlaytestResult.CooldownSnapshot(
            consecutiveDismissals: consecutiveDismissals,
            dailyNudgeCount: dailyNudgeCount,
            dailyPracticeNudgeCount: dailyPracticeNudgeCount,
            isInCooldown: isInCooldown,
            cooldownReason: cooldownReason
        )
    }

    // MARK: - False Positive Analysis

    /// Record dismissal context for false positive pattern detection
    func recordDismissalContext(analysis: StressAnalysisResponse, behaviorMetrics: BehaviorMetrics?) {
        let context = buildContextString(analysis: analysis, metrics: behaviorMetrics)
        dismissalContexts.append((context, analysis.confidence, now))

        // Keep last 30 days
        let thirtyDaysAgo = now.addingTimeInterval(-30 * 86400)
        dismissalContexts = dismissalContexts.filter { $0.timestamp > thirtyDaysAgo }
    }

    /// Build a context string from analysis and metrics for pattern matching
    private func buildContextString(analysis: StressAnalysisResponse, metrics: BehaviorMetrics?) -> String {
        var parts: [String] = []

        // Add primary signal if available
        if let signals = analysis.signals.first {
            parts.append(signals)
        }

        // Add behavioral signals
        if let metrics = metrics {
            if metrics.contextSwitchesPerMinute > 4.0 {
                parts.append("high_context_switching")
            }
            if let topApp = metrics.applicationFocus.max(by: { $0.value < $1.value })?.key {
                parts.append("focus_\(topApp)")
            }
        }

        return parts.joined(separator: ", ")
    }

    /// Get false positive patterns (contexts that were dismissed 3+ times)
    func getFalsePositivePatterns() -> [String] {
        // Count pattern occurrences
        var patternCounts: [String: Int] = [:]
        for dismissal in dismissalContexts {
            patternCounts[dismissal.context, default: 0] += 1
        }

        // Filter patterns with 3+ dismissals
        return patternCounts
            .filter { $0.value >= 3 }
            .map { "\($0.key) (\($0.value) dismissals)" }
    }

    // MARK: - Private

    @discardableResult
    private func resetDailyCountersIfNeeded() -> Bool {
        let todayStart = Calendar.current.startOfDay(for: now)
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
