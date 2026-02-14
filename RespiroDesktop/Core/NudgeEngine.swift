import Foundation
import OSLog

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

    private let logger = Logger(subsystem: "com.respiro.desktop", category: "NudgeEngine")

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
        let bSuffix = behavioralSuffix(behavioral)
        let severity = BehavioralContext.severity(behavioral)
        logger.fault("🧠 shouldNudge: weather=\(analysis.weather), nudgeType=\(analysis.nudgeType ?? "nil"), confidence=\(String(format: "%.2f", analysis.confidence)), severity=\(String(format: "%.2f", severity)), dailyNudges=\(self.dailyNudgeCount), consecutiveDismissals=\(self.consecutiveDismissals)")

        // 0. Smart suppression: video call or screen sharing active
        if let ctx = behavioral?.systemContext {
            if ctx.isOnVideoCall {
                return denied(reason: "smart_suppression_video_call" + bSuffix)
            }
            if ctx.isScreenSharing {
                return denied(reason: "smart_suppression_screen_sharing" + bSuffix)
            }
        }

        // 1. AI says don't nudge — check behavioral override
        guard let nudgeTypeRaw = analysis.nudgeType,
              let nudgeType = NudgeType(rawValue: nudgeTypeRaw) else {
            // Behavioral override: extreme distress forces practice nudge
            // Extreme severity (>= 0.85) overrides confidence gate — user is clearly in distress
            // Normal severity (0.7-0.85) still requires confidence >= 0.6
            if severity >= 0.85 {
                let overrideReason = "extreme_behavioral_override [severity=\(String(format: "%.2f", severity))\(bSuffix)]"
                return applyCooldowns(analysis: analysis, now: now, reason: overrideReason)
            }
            if severity >= 0.7 && analysis.confidence >= 0.6 {
                let overrideReason = "behavioral_override [severity=\(String(format: "%.2f", severity))\(bSuffix)]"
                return applyCooldowns(analysis: analysis, now: now, reason: overrideReason)
            }
            // Moderate behavioral stress -> encouragement nudge (lighter than practice)
            if severity >= 0.4 {
                let encourageReason = "behavioral_encouragement [severity=\(String(format: "%.2f", severity))\(bSuffix)]"
                return applyEncouragementCooldowns(now: now, reason: encourageReason, bSuffix: bSuffix)
            }
            return NudgeDecision(
                shouldShow: false, nudgeType: nil, message: nil,
                suggestedPracticeID: nil, reason: "ai_no_nudge [severity=\(String(format: "%.2f", severity))\(bSuffix)]"
            )
        }

        // 3. Behavioral contradiction: AI says nudge but behavior is calm
        if severity < 0.15 && analysis.weather == "stormy" {
            return denied(reason: "behavioral_contradiction [severity=\(String(format: "%.2f", severity))\(bSuffix)]")
        }

        // 4. Hard 5-min minimum between any nudges
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval" + bSuffix)
        }

        // 5. Post-dismissal cooldown (check early — consecutive dismissals are safety-critical)
        if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3
                ? Cooldown.consecutiveDismissalCooldown
                : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                let reason = consecutiveDismissals >= 3
                    ? "consecutive_dismissal_cooldown [\(consecutiveDismissals) dismissals]"
                    : "post_dismissal_cooldown"
                return denied(reason: reason + bSuffix)
            } else if consecutiveDismissals >= 3 {
                // 2h cooldown expired — reset counter so user gets fresh 3-dismissal allowance
                consecutiveDismissals = 0
            }
        }

        // 6. Daily total limit
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit [\(dailyNudgeCount)/\(Cooldown.maxDailyTotalNudges)]" + bSuffix)
        }

        // 7. Daily practice nudge limit
        if nudgeType == .practice && dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            return denied(reason: "daily_practice_limit [\(dailyPracticeNudgeCount)/\(Cooldown.maxDailyPracticeNudges)]" + bSuffix)
        }

        // 8. Min interval between any nudge (10 min)
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval" + bSuffix)
        }

        // 9. Min interval between practice nudges (30 min)
        if nudgeType == .practice,
           let last = lastPracticeNudgeTime,
           now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            return denied(reason: "min_practice_interval" + bSuffix)
        }

        // 10. Post-practice cooldown (45 min)
        if let last = lastPracticeCompletedTime,
           now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            let elapsed = Int(now.timeIntervalSince(last) / 60)
            return denied(reason: "post_practice_cooldown [\(elapsed)min/45min]" + bSuffix)
        }

        // 11. False positive pattern check
        // Only suppress if behavioral severity is low — high stress overrides FP patterns
        let currentContext = buildContextString(analysis: analysis, metrics: behavioral?.metrics)
        let matchingDismissals = dismissalContexts.filter { $0.context == currentContext }.count
        if matchingDismissals >= 3 && severity < 0.5 {
            return denied(reason: "false_positive_suppressed [\(matchingDismissals) prior dismissals in context '\(currentContext)']" + bSuffix)
        }

        // All checks passed
        logger.fault("✅ APPROVED: type=\(nudgeType.rawValue), reason=approved\(bSuffix)")
        return NudgeDecision(
            shouldShow: true,
            nudgeType: nudgeType,
            message: analysis.nudgeMessage,
            suggestedPracticeID: analysis.suggestedPracticeID,
            reason: "approved" + bSuffix,
            thinkingText: analysis.thinkingText,
            effortLevel: analysis.effortLevel
        )
    }

    /// Apply cooldown checks for encouragement nudges
    private func applyEncouragementCooldowns(now: Date, reason: String, bSuffix: String) -> NudgeDecision {
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval" + bSuffix)
        }
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit [\(dailyNudgeCount)/\(Cooldown.maxDailyTotalNudges)]" + bSuffix)
        }
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval" + bSuffix)
        }
        // Encouragement uses minAnyNudgeInterval (10 min), NOT minPracticeInterval (30 min)
        // minPracticeInterval only gates practice-to-practice intervals per rule definition
        if let last = lastPracticeCompletedTime, now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            let elapsed = Int(now.timeIntervalSince(last) / 60)
            return denied(reason: "post_practice_cooldown [\(elapsed)min/45min]" + bSuffix)
        }
        if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3 ? Cooldown.consecutiveDismissalCooldown : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                let reason = consecutiveDismissals >= 3 ? "consecutive_dismissal_cooldown [\(consecutiveDismissals) dismissals]" : "post_dismissal_cooldown"
                return denied(reason: reason + bSuffix)
            } else if consecutiveDismissals >= 3 {
                consecutiveDismissals = 0
            }
        }
        return NudgeDecision(
            shouldShow: true,
            nudgeType: .encouragement,
            message: "Your activity patterns suggest building stress. Consider a brief pause.",
            suggestedPracticeID: nil,
            reason: reason
        )
    }

    /// Apply cooldown checks for behavioral override nudges
    private func applyCooldowns(analysis: StressAnalysisResponse, now: Date, reason: String) -> NudgeDecision {
        let bSuffix = behavioralSuffix(nil) // no context in override path
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            return denied(reason: "hard_min_interval" + bSuffix)
        }
        // Dismissal cooldown first (safety-critical, same order as shouldNudge)
        if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3 ? Cooldown.consecutiveDismissalCooldown : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                let r = consecutiveDismissals >= 3
                    ? "consecutive_dismissal_cooldown [\(consecutiveDismissals) dismissals]"
                    : "post_dismissal_cooldown"
                return denied(reason: r + bSuffix)
            } else if consecutiveDismissals >= 3 {
                consecutiveDismissals = 0
            }
        }
        if dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            return denied(reason: "daily_total_limit" + bSuffix)
        }
        if dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            return denied(reason: "daily_practice_limit" + bSuffix)
        }
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            return denied(reason: "min_nudge_interval" + bSuffix)
        }
        if let last = lastPracticeNudgeTime, now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            return denied(reason: "min_practice_interval" + bSuffix)
        }
        if let last = lastPracticeCompletedTime, now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            return denied(reason: "post_practice_cooldown" + bSuffix)
        }
        return NudgeDecision(
            shouldShow: true,
            nudgeType: .practice,
            message: analysis.nudgeMessage ?? "Your activity patterns suggest elevated stress. A quick practice might help.",
            suggestedPracticeID: analysis.suggestedPracticeID ?? Self.defaultFallbackPracticeID(),
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

    func recordDismissal(isLater: Bool = false) {
        if isLater {
            // dismiss_later breaks the consecutive chain — user showed willingness
            consecutiveDismissals = 0
        } else {
            consecutiveDismissals += 1
        }
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

        // Order matches shouldNudge() priority: hard_min → dismissal → daily → intervals → practice cooldown
        if let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.hardMinInterval {
            isInCooldown = true
            cooldownReason = "hard_min_interval"
        } else if let last = lastDismissalTime {
            let cooldown = consecutiveDismissals >= 3
                ? Cooldown.consecutiveDismissalCooldown
                : Cooldown.postDismissalCooldown
            if now.timeIntervalSince(last) < cooldown {
                isInCooldown = true
                cooldownReason = consecutiveDismissals >= 3 ? "consecutive_dismissal_cooldown" : "post_dismissal_cooldown"
            }
        }
        if !isInCooldown && dailyNudgeCount >= Cooldown.maxDailyTotalNudges {
            isInCooldown = true
            cooldownReason = "daily_total_limit"
        } else if !isInCooldown && dailyPracticeNudgeCount >= Cooldown.maxDailyPracticeNudges {
            isInCooldown = true
            cooldownReason = "daily_practice_limit"
        } else if !isInCooldown, let last = lastNudgeTime, now.timeIntervalSince(last) < Cooldown.minAnyNudgeInterval {
            isInCooldown = true
            cooldownReason = "min_nudge_interval"
        } else if !isInCooldown, let last = lastPracticeNudgeTime, now.timeIntervalSince(last) < Cooldown.minPracticeInterval {
            isInCooldown = true
            cooldownReason = "min_practice_interval"
        } else if !isInCooldown, let last = lastPracticeCompletedTime, now.timeIntervalSince(last) < Cooldown.postPracticeCooldown {
            isInCooldown = true
            cooldownReason = "post_practice_cooldown"
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

    // MARK: - Testing Support

    /// Pre-seed dismissal contexts for testing false positive detection
    func seedDismissalContexts(_ contexts: [(context: String, confidence: Double, count: Int)]) {
        for seed in contexts {
            for _ in 0..<seed.count {
                dismissalContexts.append((seed.context, seed.confidence, now))
            }
        }
    }

    /// Build context string for external seeding (matches buildContextString format)
    func buildContextForSeeding(primarySignal: String?, contextSwitchesPerMinute: Double?, topApp: String?) -> String {
        var parts: [String] = []
        if let signal = primarySignal { parts.append(signal) }
        if let switches = contextSwitchesPerMinute, switches > 4.0 { parts.append("high_context_switching") }
        if let app = topApp { parts.append("focus_\(app)") }
        return parts.joined(separator: ", ")
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
        logger.fault("🚫 DENIED: \(reason)")
        return NudgeDecision(
            shouldShow: false, nudgeType: nil, message: nil,
            suggestedPracticeID: nil, reason: reason
        )
    }

    /// Fallback practice ID when AI doesn't suggest one. Rotates to avoid always suggesting box-breathing.
    static func defaultFallbackPracticeID() -> String {
        let fallbacks = [
            "physiological-sigh",
            "box-breathing",
            "extended-exhale",
            "grounding-54321",
            "stop-technique",
        ]
        let hour = Calendar.current.component(.hour, from: Date())
        return fallbacks[hour % fallbacks.count]
    }

    /// Build behavioral context suffix for enriched reason strings
    private func behavioralSuffix(_ behavioral: BehavioralContext?) -> String {
        guard let ctx = behavioral else { return "" }
        let switches = String(format: "%.1f", ctx.metrics.contextSwitchesPerMinute)
        let deviation = String(format: "%.0f%%", ctx.baselineDeviation * 100)
        let session = Int(ctx.metrics.sessionDuration / 60)
        let topApp = ctx.metrics.applicationFocus.max(by: { $0.value < $1.value })?.key ?? "unknown"
        let maxFocus = ctx.metrics.applicationFocus.values.max() ?? 0
        let focusLabel = maxFocus > 0.7 ? "focused" : (maxFocus > 0.4 ? "moderate" : "fragmented")
        return " [switches=\(switches)/min, baseline=\(deviation), session=\(session)min, focus=\(focusLabel)(\(topApp))]"
    }
}
