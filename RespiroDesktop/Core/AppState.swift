import SwiftUI
import SwiftData
import AppKit
import OSLog
import UserNotifications

@MainActor
@Observable
final class AppState {
    private let logger = Logger(subsystem: "com.respiro.desktop", category: "AppState")
    enum Screen: Sendable, Equatable {
        case dashboard
        case nudge
        case practice
        case weatherBefore
        case weatherAfter
        case completion
        case whatHelped
        case settings
        case onboarding
        case summary
        case practiceLibrary
    }

    var currentScreen: Screen = .dashboard
    var currentWeather: InnerWeather = .clear
    var isMonitoring: Bool = false
    var lastAnalysis: StressAnalysisResponse?
    var pendingNudge: NudgeDecision?
    var selectedWeatherBefore: InnerWeather?
    var selectedWeatherAfter: InnerWeather?
    var completedPracticeCount: Int = 0
    var lastWhatHelped: [String]?
    var lastPracticeCategory: PracticeCategory?
    var selectedPracticeID: String?
    var lastSilenceDecision: SilenceDecision?
    var secondChancePractice: Practice?
    var lastCompletedPracticeID: String?

    // MARK: - Smart Practice Selection

    /// Picks the best practice for internal/emotional stress (user-reported stormy, but screen looks calm).
    /// Avoids the last completed practice and rotates through grounding-focused options.
    /// For first-time users (no history), defaults to physiological-sigh (quick, 30s, evidence-based).
    func pickPracticeForInternalStress() -> (id: String, message: String) {
        // Grounding-focused practices: breathing + body practices best for internal stress
        let candidates: [(id: String, message: String)] = [
            ("physiological-sigh", "A quick double-inhale to reset your stress response."),
            ("box-breathing", "A rhythmic breathing pattern to calm your nervous system."),
            ("grounding-54321", "Ground yourself by noticing what you can see, hear, touch, smell, and taste."),
            ("body-scan", "A gentle scan from head to toe to release held tension."),
            ("extended-exhale", "Long exhales activate your parasympathetic nervous system."),
            ("grounding-feet", "Feel your feet on the floor and reconnect with the present moment."),
            ("stop-technique", "Stop, breathe, observe, and proceed with awareness."),
            ("self-compassion", "A moment of kindness toward yourself when things feel rough."),
        ]

        // Filter out last completed practice to avoid repetition
        let available: [(id: String, message: String)]
        if let lastID = lastCompletedPracticeID {
            let filtered = candidates.filter { $0.id != lastID }
            available = filtered.isEmpty ? candidates : filtered
        } else {
            available = candidates
        }

        // First-time user: no practice history at all -- pick physiological-sigh
        // (quickest at 60s, scientifically proven, great first experience)
        if lastCompletedPracticeID == nil && completedPracticeCount == 0 {
            return available.first { $0.id == "physiological-sigh" }
                ?? available[0]
        }

        // Rotate based on hour-of-day + day-of-week for variety across sessions
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let day = calendar.component(.weekday, from: Date())
        let rotationIndex = (hour + day) % available.count
        return available[rotationIndex]
    }

    // MARK: - Weather Check-In

    var showWeatherCheckIn: Bool = false
    var lastCheckInTime: Date?
    private let checkInCooldown: TimeInterval = 2 * 3600  // 2 hours
    private let longPauseThreshold: TimeInterval = 30 * 60  // 30 min
    var monitoringPausedAt: Date?
    var userReportedWeather: InnerWeather?
    var monitoringDiagnostic: String = ""  // Live diagnostic shown in dashboard
    var cameFromPracticeLibrary: Bool = false

    // MARK: - Weather Floor (user-reported minimum for 30 min)

    private var weatherFloor: InnerWeather?
    private var weatherFloorExpiry: Date?
    private let weatherFloorDuration: TimeInterval = 30 * 60  // 30 min

    // MARK: - Practice Effect Decay (post-practice improvement blending)

    private var practiceEffectWeather: InnerWeather?
    private var practiceEffectTime: Date?
    private let practiceEffectDecayDuration: TimeInterval = 15 * 60  // 15 min

    // MARK: - Day Summary Cache

    var cachedDaySummary: DaySummaryResponse?
    var cachedDaySummaryEntryCount: Int = 0

    // Behavioral context (populated by MonitoringService or DemoModeService)
    var currentBehaviorMetrics: BehaviorMetrics?
    var currentSystemContext: SystemContext?
    var currentBaselineDeviation: Double?
    var isOnboardingComplete: Bool = UserDefaults.standard.bool(forKey: "isOnboardingComplete") {
        didSet { UserDefaults.standard.set(isOnboardingComplete, forKey: "isOnboardingComplete") }
    }

    /// Whether user has opted to use their own API key instead of proxy
    var useOwnKey: Bool {
        UserDefaults.standard.bool(forKey: "respiro_use_own_key")
    }

    // MARK: - Demo Mode

    var isDemoMode: Bool {
        get { demoModeService?.isEnabled ?? false }
        set { demoModeService?.isEnabled = newValue }
    }

    // MARK: - Persistence

    var modelContext: ModelContext?

    // MARK: - Services

    private var monitoringService: MonitoringService?
    private var nudgeEngine: NudgeEngine?
    private var dismissalLogger: DismissalLogger?
    private var smartSuppression: SmartSuppression?
    private var demoModeService: DemoModeService?
    func configureMonitoring(service: MonitoringService) {
        self.monitoringService = service
    }

    func configureNudgeEngine(_ engine: NudgeEngine) {
        self.nudgeEngine = engine
    }

    func configureDismissalLogger(_ logger: DismissalLogger) {
        self.dismissalLogger = logger
    }

    func configureSmartSuppression(_ suppression: SmartSuppression) {
        self.smartSuppression = suppression
    }

    func configureDemoMode(_ service: DemoModeService) {
        self.demoModeService = service
    }

    func setDemoMode(_ enabled: Bool, modelContext: ModelContext) async {
        guard let service = demoModeService else { return }

        // Update the flag
        service.isEnabled = enabled

        // If enabling, seed demo data
        if enabled {
            service.seedDemoData(modelContext: modelContext)
        } else {
            // If disabling, clear demo data
            service.clearDemoData(modelContext: modelContext)
        }

        // If monitoring is active, restart it with new mode
        if isMonitoring {
            await stopMonitoring()
            await startMonitoringDirectly()
        }
    }

    // MARK: - Monitoring Control (with weather check-in gate)

    func requestStartMonitoring() {
        let now = Date()
        logger.fault("🟢 requestStartMonitoring called. lastCheckIn=\(self.lastCheckInTime?.description ?? "nil"), monitoringService=\(self.monitoringService != nil ? "YES" : "NIL")")

        // Demo mode: start immediately, no check-in
        if isDemoMode {
            Task { await startMonitoringDirectly() }
            return
        }

        // Always start monitoring immediately (don't gate on check-in)
        Task { await startMonitoringDirectly() }

        // Show check-in if needed (provides context for next analysis, not a gate)
        let needsCheckIn: Bool
        if lastCheckInTime == nil {
            // First start of day
            needsCheckIn = true
        } else if let pausedAt = monitoringPausedAt, now.timeIntervalSince(pausedAt) > longPauseThreshold {
            // Resume after long pause, respect 2h cooldown
            if let lastCheck = lastCheckInTime, now.timeIntervalSince(lastCheck) < checkInCooldown {
                needsCheckIn = false
            } else {
                needsCheckIn = true
            }
        } else {
            needsCheckIn = false
        }

        if needsCheckIn {
            logger.fault("🟡 Showing check-in (in popover)")
            showWeatherCheckIn = true
        } else {
            logger.fault("🔵 No check-in needed, starting directly")
        }
    }

    func completeWeatherCheckIn(weather: InnerWeather) {
        showWeatherCheckIn = false
        lastCheckInTime = Date()
        userReportedWeather = weather

        // Set weather floor -- AI can't rate below this for 30 min
        if weather == .stormy || weather == .cloudy {
            weatherFloor = weather
            weatherFloorExpiry = Date().addingTimeInterval(weatherFloorDuration)
        } else {
            // Clear: no floor needed
            weatherFloor = nil
            weatherFloorExpiry = nil
        }

        // Update menu bar icon to match reported weather
        currentWeather = weather

        // If user reported stormy -- offer practice immediately
        if weather == .stormy {
            let practice = pickPracticeForInternalStress()
            let nudgeMessage = "You said things are rough. \(practice.message)"
            pendingNudge = NudgeDecision(
                shouldShow: true,
                nudgeType: .practice,
                message: nudgeMessage,
                suggestedPracticeID: practice.id,
                reason: "user_reported_stormy"
            )
            showNudge()
            sendNudgeNotification(message: nudgeMessage, isInternalStress: true)
        }

        Task { await startMonitoringDirectly() }
    }

    func skipWeatherCheckIn() {
        showWeatherCheckIn = false
        Task { await startMonitoringDirectly() }
    }

    private func startMonitoringDirectly() async {
        logger.fault("🚀 startMonitoringDirectly. monitoringService=\(self.monitoringService != nil ? "YES" : "NIL"), isDemoMode=\(self.isDemoMode)")
        isMonitoring = true
        monitoringPausedAt = nil

        // Use demo mode if enabled
        if isDemoMode, let demoService = demoModeService {
            let state = self
            demoService.startDemoLoop(
                appState: self,
                onUpdate: { @Sendable weather, analysis in
                    Task { @MainActor in
                        state.updateWeather(weather, analysis: analysis)
                    }
                },
                onSilenceDecision: { @Sendable silence in
                    Task { @MainActor in
                        state.lastSilenceDecision = silence
                    }
                }
            )
        } else if let service = monitoringService {
            await service.startMonitoring()
        }
    }

    func stopMonitoring() async {
        isMonitoring = false
        monitoringPausedAt = Date()

        if isDemoMode {
            demoModeService?.stopDemoLoop()
        } else if let service = monitoringService {
            await service.stopMonitoring()
        }
    }

    /// Called by MonitoringService when user has been idle 30+ min.
    /// Pauses monitoring without stopping the service (it already stopped itself).
    func handleAutoPause() {
        logger.fault("😴 Auto-pause: user idle 30+ min")
        isMonitoring = false
        monitoringPausedAt = Date()
        monitoringDiagnostic = "Auto-paused (inactive)"
    }

    func toggleMonitoring() async {
        if isMonitoring {
            await stopMonitoring()
        } else {
            requestStartMonitoring()
        }
    }

    /// Called from MonitoringService callback when new analysis arrives.
    func updateWeather(_ weather: InnerWeather, analysis: StressAnalysisResponse) {
        logger.fault("📊 updateWeather: weather=\(weather.rawValue, privacy: .public), confidence=\(String(format: "%.2f", analysis.confidence), privacy: .public), nudgeType=\(analysis.nudgeType ?? "nil", privacy: .public), signals=\(analysis.signals.prefix(3).joined(separator: ", "), privacy: .public)")
        // Apply weather floor from user check-in
        var effectiveWeather = weather
        let floorOverridden: Bool
        if let floor = weatherFloor, let expiry = weatherFloorExpiry {
            if Date() < expiry {
                // Floor active: use the worse of (AI weather, user-reported floor)
                let weatherRank: [InnerWeather: Int] = [.clear: 0, .cloudy: 1, .stormy: 2]
                let aiRank = weatherRank[weather] ?? 0
                let floorRank = weatherRank[floor] ?? 0
                if floorRank > aiRank {
                    effectiveWeather = floor
                    floorOverridden = true
                } else {
                    floorOverridden = false
                }
            } else {
                // Floor expired
                weatherFloor = nil
                weatherFloorExpiry = nil
                floorOverridden = false
            }
        } else {
            floorOverridden = false
        }

        // Apply practice effect decay (blend AI result with post-practice improvement)
        var effectiveConfidence = analysis.confidence
        let weight = practiceEffectWeight()
        if weight > 0, let effectWeather = practiceEffectWeather {
            let aiScore = weatherToScore(effectiveWeather, confidence: analysis.confidence)
            let practiceScore = weatherToScore(effectWeather, confidence: 0.8)
            let blendedScore = aiScore * (1.0 - weight) + practiceScore * weight
            let (blendedWeather, blendedConfidence) = scoreToWeatherAndConfidence(blendedScore)
            effectiveWeather = blendedWeather
            effectiveConfidence = blendedConfidence
            logger.fault("Practice effect: weight=\(String(format: "%.0f%%", weight * 100), privacy: .public), aiScore=\(String(format: "%.1f", aiScore), privacy: .public), practiceScore=\(String(format: "%.1f", practiceScore), privacy: .public), blended=\(String(format: "%.1f", blendedScore), privacy: .public) -> \(blendedWeather.rawValue, privacy: .public)")
        }

        currentWeather = effectiveWeather
        lastAnalysis = analysis

        // Update behavioral context for dashboard display
        currentBehaviorMetrics = analysis.behaviorMetrics
        currentSystemContext = analysis.systemContext
        currentBaselineDeviation = analysis.baselineDeviation

        // Persist StressEntry to SwiftData (with blended weather if practice effect active)
        if let ctx = modelContext {
            let entry = StressEntry(
                timestamp: Date(),
                weather: effectiveWeather.rawValue,
                confidence: effectiveConfidence,
                signals: analysis.signals,
                nudgeType: analysis.nudgeType,
                nudgeMessage: analysis.nudgeMessage,
                suggestedPracticeID: analysis.suggestedPracticeID,
                screenshotInterval: 300
            )
            ctx.insert(entry)
            try? ctx.save()
        }

        // Demo mode: bypass NudgeEngine cooldowns -- create decisions directly from analysis
        if isDemoMode {
            if let nudgeTypeRaw = analysis.nudgeType,
               let nudgeType = NudgeType.from(nudgeTypeRaw) {
                var nudgeMessage = analysis.nudgeMessage
                // If floor overrode AI, acknowledge internal stress
                if floorOverridden {
                    nudgeMessage = "Your screen looks calm, but you mentioned feeling rough. A grounding exercise might help."
                }
                let decision = NudgeDecision(
                    shouldShow: true,
                    nudgeType: nudgeType,
                    message: nudgeMessage,
                    suggestedPracticeID: analysis.suggestedPracticeID,
                    reason: "demo",
                    thinkingText: analysis.thinkingText,
                    effortLevel: analysis.effortLevel
                )
                pendingNudge = decision
                if currentScreen == .dashboard {
                    showNudge()
                    sendNudgeNotification(
                        message: nudgeMessage ?? "Time for a break?",
                        isInternalStress: floorOverridden
                    )
                }
            } else if floorOverridden {
                // AI said no nudge but floor is active -- create a nudge for internal stress
                let practice = pickPracticeForInternalStress()
                let nudgeMessage = "Your screen looks calm, but you mentioned feeling rough. \(practice.message)"
                let decision = NudgeDecision(
                    shouldShow: true,
                    nudgeType: .practice,
                    message: nudgeMessage,
                    suggestedPracticeID: practice.id,
                    reason: "weather_floor_override",
                    thinkingText: analysis.thinkingText,
                    effortLevel: analysis.effortLevel
                )
                pendingNudge = decision
                if currentScreen == .dashboard {
                    showNudge()
                    sendNudgeNotification(message: nudgeMessage, isInternalStress: true)
                }
            } else {
                pendingNudge = NudgeDecision(
                    shouldShow: false, nudgeType: nil, message: nil,
                    suggestedPracticeID: nil, reason: "demo_no_nudge"
                )
                // Don't call captureSilenceDecision -- demo service handles silence via its own callback
            }
            return
        }

        // Real mode: evaluate nudge decision asynchronously via NudgeEngine
        logger.fault("🔄 About to create NudgeEngine Task. isDemoMode=\(self.isDemoMode, privacy: .public), nudgeEngine=\(self.nudgeEngine != nil, privacy: .public)")
        Task { @MainActor [weak self] in
            self?.logger.fault("🔄 NudgeEngine Task started")
            guard let self, let engine = self.nudgeEngine else {
                self?.logger.fault("⚠️ NudgeEngine Task guard failed: self=\(self != nil, privacy: .public), engine=\(self?.nudgeEngine != nil, privacy: .public)")
                return
            }

            self.logger.fault("🔍 Step 1: guard passed, checking suppression. smartSuppression=\(self.smartSuppression != nil, privacy: .public)")

            // Check smart suppression first
            if let suppression = self.smartSuppression {
                self.logger.fault("🔍 Step 2: calling shouldSuppress()")
                let suppressionResult = suppression.shouldSuppress()
                self.logger.fault("🔍 Step 3: shouldSuppress returned")
                if let denied = engine.evaluateSuppression(suppressionResult) {
                    self.logger.fault("🛑 SmartSuppression blocked nudge: \(denied.reason, privacy: .public)")
                    self.pendingNudge = denied
                    self.captureSilenceDecision(analysis: analysis, reason: denied.reason)
                    return
                }
                self.logger.fault("🔍 Step 4: suppression allowed")
            } else {
                self.logger.fault("🔍 Step 2b: no smartSuppression configured")
            }

            self.logger.fault("🔍 Step 5: building behavioral context. metrics=\(analysis.behaviorMetrics != nil, privacy: .public)")

            // Build behavioral context for rule-based override
            var behavioralCtx: BehavioralContext? = nil
            if let metrics = analysis.behaviorMetrics {
                behavioralCtx = BehavioralContext(
                    metrics: metrics,
                    baselineDeviation: analysis.baselineDeviation ?? 0.0,
                    systemContext: analysis.systemContext
                )
            }
            let severity = BehavioralContext.severity(behavioralCtx)
            self.logger.fault("🧠 NudgeEngine input: severity=\(String(format: "%.2f", severity), privacy: .public), hasBehavioral=\(behavioralCtx != nil, privacy: .public), switches=\(String(format: "%.1f", behavioralCtx?.metrics.contextSwitchesPerMinute ?? -1), privacy: .public)/min, deviation=\(String(format: "%.2f", behavioralCtx?.baselineDeviation ?? -1), privacy: .public)")
            self.logger.fault("🔍 Step 6: calling engine.shouldNudge()")
            var decision = await engine.shouldNudge(for: analysis, behavioral: behavioralCtx)
            self.logger.fault("🔍 Step 7: engine returned")

            // If floor overrode AI and engine decided not to nudge, force a nudge
            if floorOverridden && !decision.shouldShow {
                let practice = self.pickPracticeForInternalStress()
                let nudgeMessage = "Your screen looks calm, but you mentioned feeling rough. \(practice.message)"
                decision = NudgeDecision(
                    shouldShow: true,
                    nudgeType: .practice,
                    message: nudgeMessage,
                    suggestedPracticeID: practice.id,
                    reason: "weather_floor_override"
                )
            } else if floorOverridden, decision.shouldShow {
                // Override message to acknowledge internal stress
                let practice = self.pickPracticeForInternalStress()
                let nudgeMessage = "Your screen looks calm, but you mentioned feeling rough. \(practice.message)"
                decision = NudgeDecision(
                    shouldShow: true,
                    nudgeType: decision.nudgeType,
                    message: nudgeMessage,
                    suggestedPracticeID: practice.id,
                    reason: decision.reason,
                    thinkingText: decision.thinkingText,
                    effortLevel: decision.effortLevel
                )
            }

            self.logger.fault("📋 NudgeDecision: show=\(decision.shouldShow, privacy: .public), type=\(decision.nudgeType?.rawValue ?? "nil", privacy: .public), reason=\(decision.reason, privacy: .public)")
            self.pendingNudge = decision
            if decision.shouldShow, let nudgeType = decision.nudgeType {
                // If behavioral override triggered a nudge but icon is still "clear",
                // bump to "cloudy" so the icon doesn't contradict the nudge
                if self.currentWeather == .clear {
                    self.logger.fault("☁️ Bumping icon from clear→cloudy (nudge active)")
                    self.currentWeather = .cloudy
                }
                await engine.recordNudgeShown(type: nudgeType)
                self.showNudge()
                self.sendNudgeNotification(
                    message: decision.message ?? "Time for a break?",
                    isInternalStress: floorOverridden
                )
            } else if !decision.shouldShow {
                self.logger.fault("🤫 Silence: \(decision.reason, privacy: .public)")
                self.captureSilenceDecision(analysis: analysis, reason: decision.reason)
            }
        }
    }

    /// Capture a silence decision when the AI chose not to interrupt.
    private func captureSilenceDecision(analysis: StressAnalysisResponse, reason: String) {
        let weather = InnerWeather(rawValue: analysis.weather) ?? .clear
        // Only capture for non-trivial situations
        guard weather != .clear || analysis.nudgeType != nil || analysis.thinkingText != nil else { return }

        let thinking = analysis.thinkingText
            ?? "Detected \(weather.displayName.lowercased()) conditions but chose to stay quiet. Reason: \(reason.replacingOccurrences(of: "_", with: " "))."

        lastSilenceDecision = SilenceDecision(
            reason: reason,
            thinkingText: thinking,
            effortLevel: analysis.effortLevel ?? .high,
            detectedWeather: weather,
            signals: analysis.signals
        )
    }

    func notifyPracticeCompleted() async {
        // Track last completed practice for smart rotation
        if let practiceID = selectedPracticeID {
            lastCompletedPracticeID = practiceID
        }

        // Persist PracticeSession to SwiftData so Day Summary can find it
        if let ctx = modelContext {
            let session = PracticeSession(
                practiceID: selectedPracticeID ?? "unknown",
                startedAt: Date(),
                completedAt: Date(),
                weatherBefore: (selectedWeatherBefore ?? currentWeather).rawValue,
                weatherAfter: selectedWeatherAfter?.rawValue,
                wasCompleted: true,
                triggeredByNudge: pendingNudge?.shouldShow ?? false
            )
            ctx.insert(session)
            try? ctx.save()
        }

        await monitoringService?.onPracticeCompleted()
        await nudgeEngine?.recordPracticeCompleted()
    }

    func notifyDismissal(type: DismissalType = .imFine) async {
        await monitoringService?.onDismissal()
        await nudgeEngine?.recordDismissal(isLater: type == .later)

        // Log to SwiftData and update learned patterns for AI
        if let logger = dismissalLogger, let analysis = lastAnalysis {
            logger.logDismissal(
                stressEntryID: UUID(), // Will be linked to actual entry when available
                aiDetectedWeather: analysis.weather,
                dismissalType: type,
                suggestedPracticeID: analysis.suggestedPracticeID,
                contextSignals: analysis.signals
            )

            // Rebuild learned patterns and feed to monitoring service
            let patterns = logger.buildLearnedPatterns()
            await monitoringService?.updateLearnedPatterns(patterns)
        }
    }

    // MARK: - Navigation

    func showDashboard() {
        currentScreen = .dashboard
    }

    func showNudge() {
        currentScreen = .nudge
    }

    func showPractice() {
        if selectedPracticeID == nil, let suggested = pendingNudge?.suggestedPracticeID {
            selectedPracticeID = suggested
        }
        // Auto-set weatherBefore from current weather (for delta badge on completion)
        if selectedWeatherBefore == nil {
            selectedWeatherBefore = currentWeather
        }
        currentScreen = .practice
    }

    func showWeatherBefore() {
        currentScreen = .weatherBefore
    }

    func showWeatherAfter() {
        currentScreen = .weatherAfter
    }

    func showCompletion() {
        // Update menu bar icon to reflect post-practice weather
        if let after = selectedWeatherAfter {
            currentWeather = after
            // Clear weather floor — user completed practice and reported new state
            weatherFloor = nil
            weatherFloorExpiry = nil

            // Set practice effect if user improved
            let before = selectedWeatherBefore ?? currentWeather
            let rank: [InnerWeather: Int] = [.clear: 0, .cloudy: 1, .stormy: 2]
            if (rank[after] ?? 0) < (rank[before] ?? 0) {
                practiceEffectWeather = after
                practiceEffectTime = Date()
            }

            // Persist post-practice weather as a new graph point
            if let ctx = modelContext {
                let entry = StressEntry(
                    timestamp: Date(),
                    weather: after.rawValue,
                    confidence: 0.8,
                    signals: ["practice_completed"],
                    nudgeType: nil,
                    nudgeMessage: nil,
                    suggestedPracticeID: nil,
                    screenshotInterval: 300
                )
                ctx.insert(entry)
                try? ctx.save()
            }
        }
        currentScreen = .completion
    }

    func showWhatHelped() {
        currentScreen = .whatHelped
    }

    func showSettings() {
        currentScreen = .settings
    }

    func showOnboarding() {
        currentScreen = .onboarding
    }

    func showSummary() {
        currentScreen = .summary
    }

    func showPracticeLibrary() {
        currentScreen = .practiceLibrary
    }

    // MARK: - macOS Notifications

    private func sendNudgeNotification(message: String, isInternalStress: Bool) {
        let content = UNMutableNotificationContent()
        content.title = isInternalStress ? "Respiro -- checking in" : "Respiro"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "NUDGE"
        if #available(macOS 12.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // immediate
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Practice Effect Helpers

    /// Map weather + confidence to a 1-5 score matching graph levels
    /// 1 = clear high confidence (best), 5 = stormy high confidence (worst)
    private func weatherToScore(_ weather: InnerWeather, confidence: Double) -> Double {
        switch weather {
        case .clear:
            return confidence >= 0.6 ? 1.0 : 2.0
        case .cloudy:
            return 3.0
        case .stormy:
            return confidence >= 0.7 ? 5.0 : 4.0
        }
    }

    /// Map a 1-5 score back to weather + confidence for StressEntry
    private func scoreToWeatherAndConfidence(_ score: Double) -> (InnerWeather, Double) {
        if score <= 1.5 { return (.clear, 0.8) }
        if score <= 2.5 { return (.clear, 0.4) }
        if score <= 3.5 { return (.cloudy, 0.5) }
        if score <= 4.5 { return (.stormy, 0.5) }
        return (.stormy, 0.9)
    }

    /// Calculate current practice effect weight (0.0 to 0.6, decaying linearly)
    private func practiceEffectWeight() -> Double {
        guard let time = practiceEffectTime else { return 0 }
        let elapsed = Date().timeIntervalSince(time)
        if elapsed >= practiceEffectDecayDuration {
            // Expired — clear the effect
            practiceEffectWeather = nil
            practiceEffectTime = nil
            return 0
        }
        return 0.6 * (1.0 - elapsed / practiceEffectDecayDuration)
    }
}
