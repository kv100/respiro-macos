# Respiro macOS — Agent Catalog

Hackathon project: "Built with Opus 4.6" (Feb 10-16, 2026)

## Agents (6)

| File                    | Name            | Model  | Purpose                                   |
| ----------------------- | --------------- | ------ | ----------------------------------------- |
| `00-orchestrator.md`    | orchestrator    | opus   | Coordination, delegation                  |
| `02-swift-developer.md` | swift-developer | sonnet | Swift code, Claude API, services, models  |
| `03-reviewer.md`        | reviewer        | sonnet | Code quality, Swift 6 compliance          |
| `09-swiftui-pro.md`     | swiftui-pro     | sonnet | macOS UI, MenuBarExtra, animations, theme |
| `10-debugger.md`        | debugger        | haiku  | Error analysis                            |
| `11-explorer.md`        | explorer        | haiku  | File search                               |

## Document Flow

```
Orchestrator reads docs/BACKLOG.md
    |
    +-- Extracts relevant "Agent Specs" section
    |
    +-- Includes specs in agent prompt
    |
    +-- Agent implements without reading PRD
```

**Agents read `docs/BACKLOG.md`** for all technical specs (models, prompts, UI, constants).
**Agents do NOT read `docs/PRD.md`** (1100 lines — too expensive, not needed for coding).

## Invocation

```
Task({ subagent_type: "swift-developer", model: "sonnet", prompt: "..." })
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
