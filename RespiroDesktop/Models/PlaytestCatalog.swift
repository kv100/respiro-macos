import Foundation

// MARK: - Playtest Catalog (12 Scenarios: 8 Seed + 4 Behavioral)

enum PlaytestCatalog {
    static let allScenarios: [PlaytestScenario] = [
        sc1SustainedFocus,
        sc2StressEscalation,
        sc3DismissalCooldown,
        sc4PracticeCompletion,
        sc5SmartSuppression,
        sc6RapidStorms,
        sc7ManualPractice,
        sc8DailyLimit,
        // NEW: Behavioral scenarios
        sc9ContrastiveA,
        sc10ContrastiveB,
        sc11FalsePositive,
        sc12BaselineSpike,
    ]

    // MARK: - SC-1: Sustained Focus

    static let sc1SustainedFocus = PlaytestScenario(
        id: "sc-1",
        name: "Sustained Focus",
        description: "3 consecutive clear readings with no interaction. App should stay silent.",
        steps: [
            ScenarioStep(
                id: "1a",
                description: "Clear, focused work",
                mockAnalysis: .clear(confidence: 0.88, signals: ["single app focused", "clean desktop"]),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.8,
                    sessionDuration: 1800,  // 30min
                    applicationFocus: ["Xcode": 0.85, "Safari": 0.15],
                    notificationAccumulation: 1,
                    recentAppSequence: ["Xcode", "Xcode", "Safari", "Xcode", "Xcode"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: "ViewController.swift",
                    openWindowCount: 8,
                    recentAppSwitches: ["Xcode", "Safari"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 3600,
                    idleTime: 0
                ),
                baselineDeviation: 0.05  // 5% - normal
            ),
            ScenarioStep(
                id: "1b",
                description: "Still clear, coding",
                mockAnalysis: .clear(confidence: 0.85, signals: ["code editor active", "steady typing"]),
                userAction: nil,
                timeDelta: 300,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.6,
                    sessionDuration: 2100,
                    applicationFocus: ["Xcode": 0.90, "Safari": 0.10],
                    notificationAccumulation: 1,
                    recentAppSequence: ["Xcode", "Xcode", "Xcode", "Safari", "Xcode"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: "ViewController.swift",
                    openWindowCount: 8,
                    recentAppSwitches: ["Xcode"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 3900,
                    idleTime: 0
                ),
                baselineDeviation: 0.03  // 3% - normal
            ),
            ScenarioStep(
                id: "1c",
                description: "Clear, organized workspace",
                mockAnalysis: .clear(confidence: 0.90, signals: ["organized tabs", "low notification count"]),
                userAction: nil,
                timeDelta: 300,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.9,
                    sessionDuration: 2400,
                    applicationFocus: ["Xcode": 0.82, "Safari": 0.18],
                    notificationAccumulation: 2,
                    recentAppSequence: ["Xcode", "Xcode", "Safari", "Xcode", "Xcode"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: "ViewController.swift",
                    openWindowCount: 9,
                    recentAppSwitches: ["Xcode", "Safari"],
                    pendingNotificationCount: 1,
                    isOnVideoCall: false,
                    systemUptime: 4200,
                    idleTime: 0
                ),
                baselineDeviation: 0.08  // 8% - still normal
            ),
        ],
        round: 1,
        expectedBehavior: [
            "No practice nudges shown on any step",
            "Encouragement nudge possible but not required",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "1a", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "1b", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "1c", field: .nudgeShouldShow, expected: "false"),
        ]
    )

    // MARK: - SC-2: Stress Escalation

    static let sc2StressEscalation = PlaytestScenario(
        id: "sc-2",
        name: "Stress Escalation",
        description: "Weather clear → cloudy → stormy. App should suggest practice on stormy.",
        steps: [
            ScenarioStep(
                id: "2a",
                description: "Clear morning",
                mockAnalysis: .clear(confidence: 0.85, signals: ["clean inbox"]),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 1.0,
                    sessionDuration: 600,
                    applicationFocus: ["Mail": 0.60, "Calendar": 0.40],
                    notificationAccumulation: 0,
                    recentAppSequence: ["Mail", "Calendar", "Mail", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: "Inbox",
                    openWindowCount: 5,
                    recentAppSwitches: ["Mail", "Calendar"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 1200,
                    idleTime: 0
                ),
                baselineDeviation: 0.10  // 10% - normal start
            ),
            ScenarioStep(
                id: "2b",
                description: "Cloudy after meetings",
                mockAnalysis: .cloudy(confidence: 0.72, signals: ["multiple tabs", "calendar full"]),
                userAction: nil,
                timeDelta: 600,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 2.5,
                    sessionDuration: 1200,
                    applicationFocus: ["Safari": 0.40, "Zoom": 0.30, "Mail": 0.30],
                    notificationAccumulation: 5,
                    recentAppSequence: ["Zoom", "Mail", "Safari", "Zoom", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Safari",
                    activeWindowTitle: nil,
                    openWindowCount: 12,
                    recentAppSwitches: ["Zoom", "Mail", "Safari"],
                    pendingNotificationCount: 3,
                    isOnVideoCall: false,
                    systemUptime: 1800,
                    idleTime: 0
                ),
                baselineDeviation: 0.40  // 40% - moderate elevation
            ),
            ScenarioStep(
                id: "2c",
                description: "Stormy — overload",
                mockAnalysis: .stormy(
                    confidence: 0.82,
                    signals: ["47 unread messages", "rapid tab switching"],
                    nudge: .practice,
                    message: "Things look intense. Try a quick breathing exercise?",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 600,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.5,
                    sessionDuration: 1800,
                    applicationFocus: ["Slack": 0.35, "Mail": 0.35, "Safari": 0.30],
                    notificationAccumulation: 12,
                    recentAppSequence: ["Slack", "Mail", "Safari", "Slack", "Mail", "Slack"]
                ),
                systemContext: SystemContext(
                    activeApp: "Slack",
                    activeWindowTitle: nil,
                    openWindowCount: 18,
                    recentAppSwitches: ["Slack", "Mail", "Safari", "Slack"],
                    pendingNotificationCount: 8,
                    isOnVideoCall: false,
                    systemUptime: 2400,
                    idleTime: 0
                ),
                baselineDeviation: 1.5  // 150% - high stress
            ),
        ],
        round: 1,
        expectedBehavior: [
            "No nudge on clear (step 2a)",
            "No practice nudge on cloudy (step 2b)",
            "Practice nudge shown on stormy (step 2c)",
            "Breathing practice suggested (stormy + high confidence)",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "2a", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "2c", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "2c", field: .nudgeType, expected: "practice"),
        ]
    )

    // MARK: - SC-3: Dismissal Cooldown

    static let sc3DismissalCooldown = PlaytestScenario(
        id: "sc-3",
        name: "Dismissal Cooldown",
        description: "3 consecutive 'I'm Fine' dismissals on stormy → 2h cooldown. 4th stormy should NOT trigger nudge.",
        steps: [
            ScenarioStep(
                id: "3a",
                description: "Stormy — first nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.80,
                    signals: ["high tab count", "error logs visible"],
                    nudge: .practice,
                    message: "You seem stressed. Try a breathing exercise?",
                    practiceID: "box-breathing"
                ),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.2,
                    sessionDuration: 3600,
                    applicationFocus: ["Terminal": 0.50, "Editor": 0.30, "Browser": 0.20],
                    notificationAccumulation: 8,
                    recentAppSequence: ["Terminal", "Editor", "Browser", "Terminal", "Editor"]
                ),
                systemContext: SystemContext(
                    activeApp: "Terminal",
                    activeWindowTitle: "Error logs",
                    openWindowCount: 15,
                    recentAppSwitches: ["Terminal", "Editor", "Browser"],
                    pendingNotificationCount: 5,
                    isOnVideoCall: false,
                    systemUptime: 3600,
                    idleTime: 0
                ),
                baselineDeviation: 1.2  // 120% - stressed
            ),
            ScenarioStep(
                id: "3b",
                description: "User dismisses first nudge, stormy again 15min later",
                mockAnalysis: .stormy(
                    confidence: 0.78,
                    signals: ["rapid window switching", "long session"],
                    nudge: .practice,
                    message: "Still looking tense. How about a quick body scan?",
                    practiceID: "body-scan"
                ),
                userAction: .dismissImFine,
                timeDelta: 900,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.8,
                    sessionDuration: 4500,
                    applicationFocus: ["Terminal": 0.45, "Editor": 0.35, "Browser": 0.20],
                    notificationAccumulation: 10,
                    recentAppSequence: ["Terminal", "Editor", "Terminal", "Browser", "Terminal"]
                ),
                systemContext: SystemContext(
                    activeApp: "Terminal",
                    activeWindowTitle: nil,
                    openWindowCount: 16,
                    recentAppSwitches: ["Terminal", "Editor", "Browser", "Terminal"],
                    pendingNotificationCount: 7,
                    isOnVideoCall: false,
                    systemUptime: 4500,
                    idleTime: 0
                ),
                baselineDeviation: 1.4  // 140% - still stressed
            ),
            ScenarioStep(
                id: "3c",
                description: "User dismisses second nudge, stormy again 15min later",
                mockAnalysis: .stormy(
                    confidence: 0.75,
                    signals: ["cluttered desktop", "notifications piling up"],
                    nudge: .practice,
                    message: "Take a moment to ground yourself?",
                    practiceID: "five-senses"
                ),
                userAction: .dismissImFine,
                timeDelta: 900,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.0,
                    sessionDuration: 5400,
                    applicationFocus: ["Terminal": 0.40, "Editor": 0.30, "Browser": 0.30],
                    notificationAccumulation: 15,
                    recentAppSequence: ["Terminal", "Browser", "Editor", "Terminal", "Browser"]
                ),
                systemContext: SystemContext(
                    activeApp: "Browser",
                    activeWindowTitle: nil,
                    openWindowCount: 20,
                    recentAppSwitches: ["Terminal", "Browser", "Editor", "Terminal"],
                    pendingNotificationCount: 12,
                    isOnVideoCall: false,
                    systemUptime: 5400,
                    idleTime: 0
                ),
                baselineDeviation: 1.5  // 150% - elevated
            ),
            ScenarioStep(
                id: "3d",
                description: "User dismisses third nudge, stormy again 15min later — should be BLOCKED",
                mockAnalysis: .stormy(
                    confidence: 0.80,
                    signals: ["continued stress indicators"],
                    nudge: .practice,
                    message: "How about a grounding exercise?",
                    practiceID: "finger-tapping"
                ),
                userAction: .dismissImFine,
                timeDelta: 900,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.2,
                    sessionDuration: 6300,
                    applicationFocus: ["Terminal": 0.40, "Editor": 0.35, "Browser": 0.25],
                    notificationAccumulation: 18,
                    recentAppSequence: ["Terminal", "Editor", "Browser", "Terminal", "Editor"]
                ),
                systemContext: SystemContext(
                    activeApp: "Terminal",
                    activeWindowTitle: nil,
                    openWindowCount: 22,
                    recentAppSwitches: ["Terminal", "Editor", "Browser"],
                    pendingNotificationCount: 15,
                    isOnVideoCall: false,
                    systemUptime: 6300,
                    idleTime: 0
                ),
                baselineDeviation: 1.6  // 160% - high
            ),
        ],
        round: 1,
        expectedBehavior: [
            "Nudge shown on steps 3a, 3b, 3c",
            "Nudge BLOCKED on step 3d (3 consecutive dismissals → 2h cooldown)",
            "Consecutive dismissal counter reaches 3 after step 3c",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "3a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "3b", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "3c", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "3d", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "3d", field: .cooldownActive, expected: "true"),
        ]
    )

    // MARK: - SC-4: Practice Completion

    static let sc4PracticeCompletion = PlaytestScenario(
        id: "sc-4",
        name: "Practice Completion",
        description: "Stormy → practice suggested → user completes → 45-min cooldown. Next stormy within 45min blocked.",
        steps: [
            ScenarioStep(
                id: "4a",
                description: "Stormy — practice nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.85,
                    signals: ["overwhelming inbox", "multiple deadlines"],
                    nudge: .practice,
                    message: "Things are piling up. Try a physiological sigh?",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 6.0,
                    sessionDuration: 2700,
                    applicationFocus: ["Mail": 0.40, "Calendar": 0.30, "Slack": 0.30],
                    notificationAccumulation: 20,
                    recentAppSequence: ["Mail", "Slack", "Calendar", "Mail", "Slack", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: "Inbox (47 unread)",
                    openWindowCount: 18,
                    recentAppSwitches: ["Mail", "Slack", "Calendar", "Mail"],
                    pendingNotificationCount: 12,
                    isOnVideoCall: false,
                    systemUptime: 2700,
                    idleTime: 0
                ),
                baselineDeviation: 1.8  // 180% - very stressed
            ),
            ScenarioStep(
                id: "4b",
                description: "User completed practice, stormy again 10min later — should be BLOCKED",
                mockAnalysis: .stormy(
                    confidence: 0.78,
                    signals: ["still many tabs", "back to work"],
                    nudge: .practice,
                    message: "Still intense. Another breathing round?",
                    practiceID: "box-breathing"
                ),
                userAction: .completePractice,
                timeDelta: 600,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.5,
                    sessionDuration: 3300,
                    applicationFocus: ["Mail": 0.45, "Calendar": 0.30, "Slack": 0.25],
                    notificationAccumulation: 15,
                    recentAppSequence: ["Mail", "Calendar", "Mail", "Slack", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: nil,
                    openWindowCount: 18,
                    recentAppSwitches: ["Mail", "Calendar", "Slack"],
                    pendingNotificationCount: 10,
                    isOnVideoCall: false,
                    systemUptime: 3300,
                    idleTime: 0
                ),
                baselineDeviation: 1.3  // 130% - slightly reduced after practice
            ),
            ScenarioStep(
                id: "4c",
                description: "Stormy 40min after practice — still BLOCKED (within 45min cooldown)",
                mockAnalysis: .stormy(
                    confidence: 0.80,
                    signals: ["stress persists", "late afternoon"],
                    nudge: .practice,
                    message: "Try grounding yourself?",
                    practiceID: "five-senses"
                ),
                userAction: nil,
                timeDelta: 2400,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.0,
                    sessionDuration: 5700,
                    applicationFocus: ["Mail": 0.40, "Browser": 0.35, "Slack": 0.25],
                    notificationAccumulation: 18,
                    recentAppSequence: ["Mail", "Browser", "Slack", "Mail", "Browser"]
                ),
                systemContext: SystemContext(
                    activeApp: "Browser",
                    activeWindowTitle: nil,
                    openWindowCount: 20,
                    recentAppSwitches: ["Mail", "Browser", "Slack"],
                    pendingNotificationCount: 14,
                    isOnVideoCall: false,
                    systemUptime: 5700,
                    idleTime: 0
                ),
                baselineDeviation: 1.5  // 150% - still elevated
            ),
        ],
        round: 1,
        expectedBehavior: [
            "Nudge shown on step 4a",
            "Nudge BLOCKED on step 4b (post-practice 45min cooldown)",
            "Nudge BLOCKED on step 4c (still within 45min window, 40min total since practice)",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "4a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "4a", field: .nudgeType, expected: "practice"),
            PlaytestAssertion(stepID: "4b", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "4b", field: .cooldownActive, expected: "true"),
            PlaytestAssertion(stepID: "4c", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "4c", field: .cooldownActive, expected: "true"),
        ]
    )

    // MARK: - SC-5: Smart Suppression

    static let sc5SmartSuppression = PlaytestScenario(
        id: "sc-5",
        name: "Smart Suppression",
        description: "Cloudy weather with video call/screen sharing signals — AI returns no nudge. After call ends, nudge can show.",
        steps: [
            ScenarioStep(
                id: "5a",
                description: "Cloudy during video call — AI suppresses nudge",
                mockAnalysis: .cloudy(confidence: 0.70, signals: ["video call active", "multiple participants"]),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 1.5,
                    sessionDuration: 1800,
                    applicationFocus: ["Zoom": 0.85, "Slack": 0.15],
                    notificationAccumulation: 3,
                    recentAppSequence: ["Zoom", "Zoom", "Slack", "Zoom", "Zoom"]
                ),
                systemContext: SystemContext(
                    activeApp: "Zoom",
                    activeWindowTitle: "Team Standup",
                    openWindowCount: 10,
                    recentAppSwitches: ["Zoom", "Slack"],
                    pendingNotificationCount: 2,
                    isOnVideoCall: true,
                    systemUptime: 1800,
                    idleTime: 0
                ),
                baselineDeviation: 0.20  // 20% - elevated but on video call
            ),
            ScenarioStep(
                id: "5b",
                description: "Cloudy during screen sharing — AI suppresses nudge",
                mockAnalysis: .cloudy(confidence: 0.68, signals: ["screen sharing", "presentation mode"]),
                userAction: nil,
                timeDelta: 600,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.8,
                    sessionDuration: 2400,
                    applicationFocus: ["Zoom": 0.90, "Keynote": 0.10],
                    notificationAccumulation: 5,
                    recentAppSequence: ["Zoom", "Zoom", "Keynote", "Zoom", "Zoom"]
                ),
                systemContext: SystemContext(
                    activeApp: "Zoom",
                    activeWindowTitle: "Presenting...",
                    openWindowCount: 12,
                    recentAppSwitches: ["Zoom", "Keynote"],
                    pendingNotificationCount: 4,
                    isOnVideoCall: true,
                    systemUptime: 2400,
                    idleTime: 0
                ),
                baselineDeviation: 0.10  // 10% - low during presentation
            ),
            ScenarioStep(
                id: "5c",
                description: "Cloudy, call ended — AI suggests practice",
                mockAnalysis: .stormy(
                    confidence: 0.75,
                    signals: ["post-meeting fatigue", "many open windows"],
                    nudge: .practice,
                    message: "Meeting marathon over. A quick reset?",
                    practiceID: "body-scan"
                ),
                userAction: nil,
                timeDelta: 1200,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.0,
                    sessionDuration: 3600,
                    applicationFocus: ["Mail": 0.35, "Slack": 0.35, "Browser": 0.30],
                    notificationAccumulation: 15,
                    recentAppSequence: ["Mail", "Slack", "Browser", "Mail", "Slack", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: nil,
                    openWindowCount: 16,
                    recentAppSwitches: ["Mail", "Slack", "Browser", "Mail"],
                    pendingNotificationCount: 10,
                    isOnVideoCall: false,
                    systemUptime: 3600,
                    idleTime: 0
                ),
                baselineDeviation: 1.2  // 120% - post-meeting spike
            ),
        ],
        round: 1,
        expectedBehavior: [
            "No nudge on step 5a (AI sees video call, returns no nudge type)",
            "No nudge on step 5b (AI sees screen sharing, returns no nudge type)",
            "Nudge shown on step 5c (call ended, AI suggests practice)",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "5a", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "5b", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "5c", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "5c", field: .nudgeType, expected: "practice"),
        ]
    )

    // MARK: - SC-6: Rapid Storms

    static let sc6RapidStorms = PlaytestScenario(
        id: "sc-6",
        name: "Rapid Storms",
        description: "Two stormy readings 10 min apart. First triggers nudge, second blocked by minimum interval.",
        steps: [
            ScenarioStep(
                id: "6a",
                description: "Stormy — first nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.83,
                    signals: ["frantic typing", "error messages on screen"],
                    nudge: .practice,
                    message: "Looks like you hit a wall. Try a breathing exercise?",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 7.5,
                    sessionDuration: 2400,
                    applicationFocus: ["Terminal": 0.55, "Editor": 0.30, "Browser": 0.15],
                    notificationAccumulation: 10,
                    recentAppSequence: ["Terminal", "Editor", "Browser", "Terminal", "Editor", "Terminal"]
                ),
                systemContext: SystemContext(
                    activeApp: "Terminal",
                    activeWindowTitle: "Error: Segmentation fault",
                    openWindowCount: 12,
                    recentAppSwitches: ["Terminal", "Editor", "Browser", "Terminal"],
                    pendingNotificationCount: 8,
                    isOnVideoCall: false,
                    systemUptime: 2400,
                    idleTime: 0
                ),
                baselineDeviation: 2.5  // 250% - very high, frantic
            ),
            ScenarioStep(
                id: "6b",
                description: "Stormy again 10min later — should be BLOCKED (minimum interval)",
                mockAnalysis: .stormy(
                    confidence: 0.80,
                    signals: ["still debugging", "stack overflow open"],
                    nudge: .practice,
                    message: "Still stuck? A quick break might help.",
                    practiceID: "box-breathing"
                ),
                userAction: nil,
                timeDelta: 600,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 8.0,
                    sessionDuration: 3000,
                    applicationFocus: ["Browser": 0.50, "Terminal": 0.35, "Editor": 0.15],
                    notificationAccumulation: 12,
                    recentAppSequence: ["Browser", "Terminal", "Browser", "Terminal", "Browser", "Terminal"]
                ),
                systemContext: SystemContext(
                    activeApp: "Browser",
                    activeWindowTitle: "Stack Overflow - Debugging...",
                    openWindowCount: 15,
                    recentAppSwitches: ["Browser", "Terminal", "Browser", "Terminal"],
                    pendingNotificationCount: 10,
                    isOnVideoCall: false,
                    systemUptime: 3000,
                    idleTime: 0
                ),
                baselineDeviation: 2.8  // 280% - even higher, still stuck
            ),
        ],
        round: 1,
        expectedBehavior: [
            "Nudge shown on step 6a",
            "Nudge BLOCKED on step 6b (minimum 30min practice nudge interval not met)",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "6a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "6a", field: .nudgeType, expected: "practice"),
            PlaytestAssertion(stepID: "6b", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "6b", field: .cooldownActive, expected: "true"),
        ]
    )

    // MARK: - SC-7: Manual Practice

    static let sc7ManualPractice = PlaytestScenario(
        id: "sc-7",
        name: "Manual Practice",
        description: "User starts practice during clear weather. No nudge needed. Practice session logged.",
        steps: [
            ScenarioStep(
                id: "7a",
                description: "Clear weather, user starts practice manually",
                mockAnalysis: .clear(confidence: 0.90, signals: ["relaxed workspace", "few tabs"]),
                userAction: .startPractice,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.5,
                    sessionDuration: 900,
                    applicationFocus: ["Music": 0.60, "Notes": 0.40],
                    notificationAccumulation: 0,
                    recentAppSequence: ["Music", "Notes", "Music", "Notes", "Music"]
                ),
                systemContext: SystemContext(
                    activeApp: "Music",
                    activeWindowTitle: "Meditation Playlist",
                    openWindowCount: 5,
                    recentAppSwitches: ["Music", "Notes"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 900,
                    idleTime: 0
                ),
                baselineDeviation: 0.02  // 2% - very calm
            ),
            ScenarioStep(
                id: "7b",
                description: "Clear weather, user completes practice",
                mockAnalysis: .clear(confidence: 0.92, signals: ["calm environment"]),
                userAction: .completePractice,
                timeDelta: 60,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.2,
                    sessionDuration: 960,
                    applicationFocus: ["Music": 0.80, "Notes": 0.20],
                    notificationAccumulation: 0,
                    recentAppSequence: ["Music", "Music", "Music", "Music", "Notes"]
                ),
                systemContext: SystemContext(
                    activeApp: "Music",
                    activeWindowTitle: "Meditation Playlist",
                    openWindowCount: 5,
                    recentAppSwitches: ["Music"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 960,
                    idleTime: 0
                ),
                baselineDeviation: 0.01  // 1% - very relaxed
            ),
            ScenarioStep(
                id: "7c",
                description: "Clear weather, back to work",
                mockAnalysis: .clear(confidence: 0.88, signals: ["focused work resumed"]),
                userAction: nil,
                timeDelta: 300,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 1.0,
                    sessionDuration: 1260,
                    applicationFocus: ["Xcode": 0.85, "Safari": 0.15],
                    notificationAccumulation: 1,
                    recentAppSequence: ["Xcode", "Xcode", "Safari", "Xcode", "Xcode"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: "ContentView.swift",
                    openWindowCount: 7,
                    recentAppSwitches: ["Xcode", "Safari"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 1260,
                    idleTime: 0
                ),
                baselineDeviation: 0.08  // 8% - normal focused work
            ),
        ],
        round: 1,
        expectedBehavior: [
            "No nudges on any step (weather is clear)",
            "Practice session recorded correctly",
            "Post-practice cooldown activated after 7b",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "7a", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "7b", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "7c", field: .nudgeShouldShow, expected: "false"),
        ]
    )

    // MARK: - SC-8: Daily Limit

    static let sc8DailyLimit = PlaytestScenario(
        id: "sc-8",
        name: "Daily Limit",
        description: "7 stormy entries across a day. Practice nudges 1-6 shown, 7th blocked (maxDailyPracticeNudges: 6).",
        steps: [
            ScenarioStep(
                id: "8a",
                description: "Stormy #1 — nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.80, signals: ["morning rush"],
                    nudge: .practice, message: "Rough start. Try breathing?",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.0,
                    sessionDuration: 900,
                    applicationFocus: ["Mail": 0.50, "Calendar": 0.30, "Slack": 0.20],
                    notificationAccumulation: 10,
                    recentAppSequence: ["Mail", "Calendar", "Slack", "Mail", "Calendar"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: nil,
                    openWindowCount: 12,
                    recentAppSwitches: ["Mail", "Calendar", "Slack"],
                    pendingNotificationCount: 8,
                    isOnVideoCall: false,
                    systemUptime: 900,
                    idleTime: 0
                ),
                baselineDeviation: 1.5  // 150%
            ),
            ScenarioStep(
                id: "8b",
                description: "Stormy #2 — nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.78, signals: ["back-to-back meetings"],
                    nudge: .practice, message: "Meeting overload. Quick reset?",
                    practiceID: "box-breathing"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 3.5,
                    sessionDuration: 2701,
                    applicationFocus: ["Zoom": 0.70, "Slack": 0.20, "Notes": 0.10],
                    notificationAccumulation: 8,
                    recentAppSequence: ["Zoom", "Slack", "Zoom", "Zoom", "Notes"]
                ),
                systemContext: SystemContext(
                    activeApp: "Zoom",
                    activeWindowTitle: nil,
                    openWindowCount: 10,
                    recentAppSwitches: ["Zoom", "Slack"],
                    pendingNotificationCount: 6,
                    isOnVideoCall: false,
                    systemUptime: 2701,
                    idleTime: 0
                ),
                baselineDeviation: 1.0  // 100%
            ),
            ScenarioStep(
                id: "8c",
                description: "Stormy #3 — nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.82, signals: ["urgent slack messages"],
                    nudge: .practice, message: "Things heating up. Ground yourself?",
                    practiceID: "five-senses"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 6.0,
                    sessionDuration: 4502,
                    applicationFocus: ["Slack": 0.55, "Mail": 0.30, "Browser": 0.15],
                    notificationAccumulation: 15,
                    recentAppSequence: ["Slack", "Mail", "Slack", "Browser", "Slack", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Slack",
                    activeWindowTitle: nil,
                    openWindowCount: 15,
                    recentAppSwitches: ["Slack", "Mail", "Browser"],
                    pendingNotificationCount: 12,
                    isOnVideoCall: false,
                    systemUptime: 4502,
                    idleTime: 0
                ),
                baselineDeviation: 1.8  // 180%
            ),
            ScenarioStep(
                id: "8d",
                description: "Stormy #4 — nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.76, signals: ["deadline approaching"],
                    nudge: .practice, message: "Deadline pressure. Quick body scan?",
                    practiceID: "body-scan"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.5,
                    sessionDuration: 6303,
                    applicationFocus: ["Xcode": 0.45, "Terminal": 0.30, "Browser": 0.25],
                    notificationAccumulation: 10,
                    recentAppSequence: ["Xcode", "Terminal", "Browser", "Xcode", "Terminal"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: nil,
                    openWindowCount: 18,
                    recentAppSwitches: ["Xcode", "Terminal", "Browser"],
                    pendingNotificationCount: 8,
                    isOnVideoCall: false,
                    systemUptime: 6303,
                    idleTime: 0
                ),
                baselineDeviation: 1.6  // 160%
            ),
            ScenarioStep(
                id: "8e",
                description: "Stormy #5 — nudge shown",
                mockAnalysis: .stormy(
                    confidence: 0.79, signals: ["error cascade"],
                    nudge: .practice, message: "Tough afternoon. Try finger tapping?",
                    practiceID: "finger-tapping"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 7.0,
                    sessionDuration: 8104,
                    applicationFocus: ["Terminal": 0.50, "Editor": 0.30, "Browser": 0.20],
                    notificationAccumulation: 12,
                    recentAppSequence: ["Terminal", "Editor", "Terminal", "Browser", "Terminal", "Editor"]
                ),
                systemContext: SystemContext(
                    activeApp: "Terminal",
                    activeWindowTitle: "Errors",
                    openWindowCount: 20,
                    recentAppSwitches: ["Terminal", "Editor", "Browser", "Terminal"],
                    pendingNotificationCount: 10,
                    isOnVideoCall: false,
                    systemUptime: 8104,
                    idleTime: 0
                ),
                baselineDeviation: 2.2  // 220%
            ),
            ScenarioStep(
                id: "8f",
                description: "Stormy #6 — nudge shown (last allowed)",
                mockAnalysis: .stormy(
                    confidence: 0.81, signals: ["late day fatigue"],
                    nudge: .practice, message: "Long day. One more breathing exercise?",
                    practiceID: "4-7-8-breathing"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.5,
                    sessionDuration: 9905,
                    applicationFocus: ["Mail": 0.40, "Slack": 0.35, "Calendar": 0.25],
                    notificationAccumulation: 18,
                    recentAppSequence: ["Mail", "Slack", "Calendar", "Mail", "Slack"]
                ),
                systemContext: SystemContext(
                    activeApp: "Mail",
                    activeWindowTitle: nil,
                    openWindowCount: 16,
                    recentAppSwitches: ["Mail", "Slack", "Calendar"],
                    pendingNotificationCount: 15,
                    isOnVideoCall: false,
                    systemUptime: 9905,
                    idleTime: 0
                ),
                baselineDeviation: 1.3  // 130%
            ),
            ScenarioStep(
                id: "8g",
                description: "Stormy #7 — should be BLOCKED (daily limit reached)",
                mockAnalysis: .stormy(
                    confidence: 0.83, signals: ["end of day burnout"],
                    nudge: .practice, message: "Almost done. Try a quick reset?",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 1801,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 5.0,
                    sessionDuration: 11706,
                    applicationFocus: ["Mail": 0.35, "Slack": 0.35, "Browser": 0.30],
                    notificationAccumulation: 20,
                    recentAppSequence: ["Mail", "Slack", "Browser", "Mail", "Slack", "Mail"]
                ),
                systemContext: SystemContext(
                    activeApp: "Slack",
                    activeWindowTitle: nil,
                    openWindowCount: 18,
                    recentAppSwitches: ["Mail", "Slack", "Browser"],
                    pendingNotificationCount: 18,
                    isOnVideoCall: false,
                    systemUptime: 11706,
                    idleTime: 0
                ),
                baselineDeviation: 1.5  // 150%
            ),
        ],
        round: 1,
        expectedBehavior: [
            "Practice nudges shown on steps 8a through 8f (6 total)",
            "Practice nudge BLOCKED on step 8g (maxDailyPracticeNudges: 6 reached)",
            "Daily practice nudge counter increments correctly",
        ],
        hypothesis: nil,
        assertions: [
            PlaytestAssertion(stepID: "8a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8b", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8c", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8d", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8e", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8f", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "8g", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "8g", field: .cooldownActive, expected: "true"),
        ]
    )

    // MARK: - SC-9: Contrastive Pair A - Calm Behavior

    static let sc9ContrastiveA = PlaytestScenario(
        id: "sc-9",
        name: "Contrastive A: Same Screen, Calm Behavior",
        description: "20 tabs, Slack open, notifications BUT calm behavior (low switches, focused). Should NOT trigger nudge.",
        steps: [
            ScenarioStep(
                id: "9a",
                description: "Busy screen but organized work",
                mockAnalysis: .cloudy(confidence: 0.65, signals: ["20 tabs", "Slack active", "5 notifications"]),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 0.4,  // LOW - focused
                    sessionDuration: 1800,           // 30min
                    applicationFocus: ["Xcode": 0.85, "Slack": 0.10, "Safari": 0.05],
                    notificationAccumulation: 5,
                    recentAppSequence: ["Xcode", "Xcode", "Xcode", "Slack", "Xcode"]
                ),
                systemContext: SystemContext(
                    activeApp: "Xcode",
                    activeWindowTitle: nil,
                    openWindowCount: 20,
                    recentAppSwitches: ["Xcode", "Slack"],
                    pendingNotificationCount: 5,
                    isOnVideoCall: false,
                    systemUptime: 7200,
                    idleTime: 0
                ),
                baselineDeviation: 0.05  // 5% - normal for this user
            )
        ],
        round: 2,
        expectedBehavior: [
            "No practice nudge despite visual clutter",
            "Behavioral context shows focused work",
            "Baseline deviation low (5%)",
        ],
        hypothesis: "Visual chaos + calm behavior = no nudge (test behavioral override)",
        assertions: [
            PlaytestAssertion(stepID: "9a", field: .nudgeShouldShow, expected: "false"),
            PlaytestAssertion(stepID: "9a", field: .behavioralContextUsed, expected: "true"),
        ]
    )

    // MARK: - SC-10: Contrastive Pair B - Frantic Behavior

    static let sc10ContrastiveB = PlaytestScenario(
        id: "sc-10",
        name: "Contrastive B: Same Screen, Frantic Behavior",
        description: "20 tabs, Slack open, notifications AND frantic behavior (high switches, fragmented). SHOULD trigger nudge.",
        steps: [
            ScenarioStep(
                id: "10a",
                description: "Same busy screen but stressed behavior",
                mockAnalysis: .cloudy(confidence: 0.65, signals: ["20 tabs", "Slack active", "5 notifications"]),  // SAME as SC-9
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 6.5,  // HIGH - frantic
                    sessionDuration: 9000,           // 2.5h no break
                    applicationFocus: ["Xcode": 0.30, "Slack": 0.35, "Safari": 0.35],  // fragmented
                    notificationAccumulation: 15,
                    recentAppSequence: ["Xcode", "Slack", "Safari", "Slack", "Xcode", "Slack"]
                ),
                systemContext: SystemContext(
                    activeApp: "Slack",
                    activeWindowTitle: nil,
                    openWindowCount: 20,
                    recentAppSwitches: ["Xcode", "Slack", "Safari", "Slack", "Xcode"],
                    pendingNotificationCount: 15,
                    isOnVideoCall: false,
                    systemUptime: 9000,
                    idleTime: 0
                ),
                baselineDeviation: 2.8  // 280% - VERY HIGH
            )
        ],
        round: 2,
        expectedBehavior: [
            "Practice nudge shown despite same visual",
            "Behavioral context shows stress (6.5 switches/min, 280% deviation)",
            "Demonstrates behavioral analysis works",
        ],
        hypothesis: "Same visual + frantic behavior = nudge (test behavioral detection)",
        assertions: [
            PlaytestAssertion(stepID: "10a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "10a", field: .nudgeType, expected: "practice"),
            PlaytestAssertion(stepID: "10a", field: .behavioralContextUsed, expected: "true"),
            PlaytestAssertion(stepID: "10a", field: .baselineDeviationConsidered, expected: "true"),
        ]
    )

    // MARK: - SC-11: False Positive Pattern

    static let sc11FalsePositive = PlaytestScenario(
        id: "sc-11",
        name: "False Positive: Code Review Pattern",
        description: "Visual chaos (many tabs, GitHub PR, errors) but user has dismissed 5x during code reviews. Should have lower confidence or no nudge.",
        steps: [
            ScenarioStep(
                id: "11a",
                description: "Code review — looks stressful but normal for user",
                mockAnalysis: .stormy(
                    confidence: 0.70,
                    signals: ["GitHub PR open", "terminal with errors", "15 tabs"],
                    nudge: .practice,
                    message: "Looks intense...",
                    practiceID: "physiological-sigh"
                ),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 4.0,
                    sessionDuration: 3600,
                    applicationFocus: ["Browser": 0.50, "Terminal": 0.30, "Editor": 0.20],
                    notificationAccumulation: 3,
                    recentAppSequence: ["Browser", "Terminal", "Browser", "Editor", "Browser"]
                ),
                systemContext: SystemContext(
                    activeApp: "Safari",
                    activeWindowTitle: "Pull Request #123",
                    openWindowCount: 15,
                    recentAppSwitches: ["Safari", "Terminal"],
                    pendingNotificationCount: 0,
                    isOnVideoCall: false,
                    systemUptime: 3600,
                    idleTime: 0
                ),
                baselineDeviation: 0.8  // 80% - elevated but not extreme
            )
        ],
        round: 2,
        expectedBehavior: [
            "Lower confidence due to learned false positive pattern",
            "User dismissed this context 5 times before",
            "AI should mention false positive history",
        ],
        hypothesis: "Visual stress + learned FP pattern = lower confidence (test FP learning)",
        assertions: [
            // This one is tricky - might show nudge but with lower confidence
            // Or might not show nudge at all
            // Leave flexible for evaluation
        ]
    )

    // MARK: - SC-12: Baseline Deviation Spike

    static let sc12BaselineSpike = PlaytestScenario(
        id: "sc-12",
        name: "Baseline Deviation Spike",
        description: "Moderate visual activity but HUGE behavioral spike (8/min vs 2/min baseline = 300%). Should detect via baseline.",
        steps: [
            ScenarioStep(
                id: "12a",
                description: "Moderate tabs but frantic switching",
                mockAnalysis: .cloudy(confidence: 0.60, signals: ["10 tabs", "multiple apps"]),
                userAction: nil,
                timeDelta: 0,
                behaviorMetrics: BehaviorMetrics(
                    contextSwitchesPerMinute: 8.0,  // VERY HIGH
                    sessionDuration: 1800,
                    applicationFocus: ["App1": 0.25, "App2": 0.25, "App3": 0.25, "App4": 0.25],
                    notificationAccumulation: 8,
                    recentAppSequence: ["App1", "App2", "App3", "App4", "App1", "App2"]
                ),
                systemContext: SystemContext(
                    activeApp: "App1",
                    activeWindowTitle: nil,
                    openWindowCount: 10,
                    recentAppSwitches: ["App1", "App2", "App3", "App4"],
                    pendingNotificationCount: 8,
                    isOnVideoCall: false,
                    systemUptime: 1800,
                    idleTime: 0
                ),
                baselineDeviation: 3.0  // 300% - EXTREME spike
            )
        ],
        round: 2,
        expectedBehavior: [
            "Practice nudge due to extreme baseline deviation",
            "AI should mention '300% above baseline' or similar",
            "Context switching rate flagged",
        ],
        hypothesis: "Moderate visual + 300% baseline spike = nudge (test baseline detection)",
        assertions: [
            PlaytestAssertion(stepID: "12a", field: .nudgeShouldShow, expected: "true"),
            PlaytestAssertion(stepID: "12a", field: .nudgeType, expected: "practice"),
            PlaytestAssertion(stepID: "12a", field: .baselineDeviationConsidered, expected: "true"),
        ]
    )
}
