import Foundation

// MARK: - Playtest Catalog (8 Seed Scenarios)

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
                timeDelta: 0
            ),
            ScenarioStep(
                id: "1b",
                description: "Still clear, coding",
                mockAnalysis: .clear(confidence: 0.85, signals: ["code editor active", "steady typing"]),
                userAction: nil,
                timeDelta: 300
            ),
            ScenarioStep(
                id: "1c",
                description: "Clear, organized workspace",
                mockAnalysis: .clear(confidence: 0.90, signals: ["organized tabs", "low notification count"]),
                userAction: nil,
                timeDelta: 300
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
                timeDelta: 0
            ),
            ScenarioStep(
                id: "2b",
                description: "Cloudy after meetings",
                mockAnalysis: .cloudy(confidence: 0.72, signals: ["multiple tabs", "calendar full"]),
                userAction: nil,
                timeDelta: 600
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
                timeDelta: 600
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
                timeDelta: 0
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
                timeDelta: 900
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
                timeDelta: 900
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
                timeDelta: 900
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
                timeDelta: 0
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
                timeDelta: 600
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
                timeDelta: 2400
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
                timeDelta: 0
            ),
            ScenarioStep(
                id: "5b",
                description: "Cloudy during screen sharing — AI suppresses nudge",
                mockAnalysis: .cloudy(confidence: 0.68, signals: ["screen sharing", "presentation mode"]),
                userAction: nil,
                timeDelta: 600
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
                timeDelta: 1200
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
                timeDelta: 0
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
                timeDelta: 600
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
                timeDelta: 0
            ),
            ScenarioStep(
                id: "7b",
                description: "Clear weather, user completes practice",
                mockAnalysis: .clear(confidence: 0.92, signals: ["calm environment"]),
                userAction: .completePractice,
                timeDelta: 60
            ),
            ScenarioStep(
                id: "7c",
                description: "Clear weather, back to work",
                mockAnalysis: .clear(confidence: 0.88, signals: ["focused work resumed"]),
                userAction: nil,
                timeDelta: 300
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
                timeDelta: 0
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
                timeDelta: 1801
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
                timeDelta: 1801
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
                timeDelta: 1801
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
                timeDelta: 1801
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
                timeDelta: 1801
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
                timeDelta: 1801
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
}
