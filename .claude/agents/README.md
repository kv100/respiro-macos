# Respiro macOS — Agent Catalog

Hackathon project: "Built with Opus 4.6" (Feb 10-16, 2026)

## Agents (6)

| File                    | Name            | Model    | Skills                                                                                     | Purpose                                   |
| ----------------------- | --------------- | -------- | ------------------------------------------------------------------------------------------ | ----------------------------------------- |
| `00-orchestrator.md`    | orchestrator    | opus     | all                                                                                        | Coordination, delegation                  |
| `02-swift-developer.md` | swift-developer | **opus** | swift-patterns, swiftui-components, claude-api-swift, screencapturekit, swiftdata-patterns | Swift code, Claude API, services, models  |
| `03-reviewer.md`        | reviewer        | sonnet   | swift-patterns, swiftui-components, claude-api-swift, swiftdata-patterns                   | Code quality, Swift 6 compliance          |
| `09-swiftui-pro.md`     | swiftui-pro     | sonnet   | swiftui-components, swift-patterns, macos-menubar                                          | macOS UI, MenuBarExtra, animations, theme |
| `10-debugger.md`        | debugger        | haiku    | swift-patterns, claude-api-swift                                                           | Error analysis, crash investigation       |
| `11-explorer.md`        | explorer        | haiku    | —                                                                                          | File search, codebase navigation          |

## Skills (7)

| Skill                | File                                  | Used By                                          |
| -------------------- | ------------------------------------- | ------------------------------------------------ |
| `swift-patterns`     | skills/swift-patterns/QUICKREF.md     | swift-developer, reviewer, swiftui-pro, debugger |
| `swiftui-components` | skills/swiftui-components/QUICKREF.md | swift-developer, reviewer, swiftui-pro           |
| `claude-api-swift`   | skills/claude-api-swift/QUICKREF.md   | swift-developer, reviewer, debugger              |
| `screencapturekit`   | skills/screencapturekit/QUICKREF.md   | swift-developer                                  |
| `swiftdata-patterns` | skills/swiftdata-patterns/QUICKREF.md | swift-developer, reviewer                        |
| `macos-menubar`      | skills/macos-menubar/QUICKREF.md      | swiftui-pro                                      |
| `swift-testing`      | skills/swift-testing/QUICKREF.md      | (testing)                                        |

## Commands

| Command          | File                      | Purpose                         |
| ---------------- | ------------------------- | ------------------------------- |
| `/build-verify`  | commands/build-verify.md  | Build + quality checks pipeline |
| `/reflect`       | commands/reflect.md       | Session reflection              |
| `/memory-search` | commands/memory-search.md | Search past sessions            |

## Document Flow

```
Orchestrator reads docs/BACKLOG.md
    |
    +-- Extracts relevant "Agent Specs" section
    |
    +-- Includes specs in agent prompt
    |
    +-- Agent implements using skills as reference
```

**Agents read `docs/BACKLOG.md`** for all technical specs.
**Agents reference skills** for implementation patterns.
**Agents do NOT read `docs/PRD.md`** (1100 lines — too expensive).

## Invocation

```
Task({ subagent_type: "swift-developer", model: "opus", prompt: "..." })
Task({ subagent_type: "swiftui-pro", model: "sonnet", prompt: "..." })
Task({ subagent_type: "reviewer", model: "sonnet", prompt: "..." })
Task({ subagent_type: "explorer", model: "haiku", prompt: "..." })
Task({ subagent_type: "debugger", model: "haiku", prompt: "..." })
```

## Hackathon Focus

- Speed > perfection
- @Observable + actor Services (NO TCA)
- SwiftUI animations only (NO Metal)
- macOS 14+ MenuBarExtra with `.window` style
- Claude Opus 4.6 Vision API
- Heritage Jade dark theme (#0A1F1A / #10B981)
- Zero external dependencies
