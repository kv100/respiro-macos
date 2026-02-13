# Orchestrator Role

Base Claude = Orchestrator (Opus). Reads documents as needed.

## Document Index

| Document                       | What                       | When to read                   |
| ------------------------------ | -------------------------- | ------------------------------ |
| **`docs/BACKLOG.md`**          | Tasks + Agent Specs        | **Before any task delegation** |
| `docs/PRD.md`                  | Full PRD (strategy, flows) | Only for strategic context     |
| `.claude/agents/README.md`     | Agent catalog              | Agent selection                |
| `.claude/skills/*/QUICKREF.md` | Technology specifics       | When needed                    |

**RULE:** Always include relevant "Agent Specs" section from `docs/BACKLOG.md` in agent prompts. Agents should NOT need to read the full PRD.

## Model Selection (MANDATORY)

| Model      | Cost | Agents                | When                               |
| ---------- | ---- | --------------------- | ---------------------------------- |
| **haiku**  | $    | explorer, debugger    | Search, find files, quick analysis |
| **sonnet** | $$   | reviewer, swiftui-pro | Review, UI                         |
| **opus**   | $$$  | swift-developer       | Core implementation (25%+ Opus)    |

### Invocation (ALWAYS specify model!)

```
// Research/Search (Haiku - cheap)
Task({ subagent_type: "explorer", model: "haiku", prompt: "..." })
Task({ subagent_type: "debugger", model: "haiku", prompt: "..." })

// UI/Review (Sonnet - balanced)
Task({ subagent_type: "swiftui-pro", model: "sonnet", prompt: "..." })
Task({ subagent_type: "reviewer", model: "sonnet", prompt: "..." })

// Core Implementation (Opus - best quality, 25%+ of agent calls)
Task({ subagent_type: "swift-developer", model: "opus", prompt: "..." })
```

### Quick Decision

- "Find file/code" -> explorer (haiku)
- "Fix bug/error" -> debugger (haiku) -> swift-developer (opus)
- "Write code" -> swift-developer (opus)
- "UI/Animation" -> swiftui-pro (sonnet)
- "Review code" -> reviewer (sonnet)

## User Override (HIGHEST PRIORITY)

If user explicitly asks for "agent team" / "parallel" / "team" ->
ALWAYS use Agent Team (TeamCreate), even if task seems simple enough for subagents.

## Team Cleanup (MANDATORY)

After all team tasks are complete:

1. `SendMessage(shutdown_request)` to ALL teammates
2. Wait for shutdown confirmations
3. `TeamDelete` to clean up

NEVER leave teams running. User should not have to clean up manually.

---

## How to Delegate Tasks

### Prompt Template for Agents

When delegating a backlog task (e.g., P0.4), include in the prompt:

1. **Task ID and description** from the backlog table
2. **Relevant "Agent Specs" section** — copy the specific section from BACKLOG.md
3. **File paths** — where to create/edit files (from Project Structure)
4. **Dependencies** — what already exists that agent should use

Example:

```
Implement P0.4: ClaudeVisionClient — send screenshot to Opus 4.6, parse JSON.

Read docs/BACKLOG.md for full specs. Key sections:
- "Agent Specs — AI Prompts" for system prompt and per-screenshot template
- "Agent Specs — Data Models" for StressAnalysisResponse struct
- "Architecture & Project Structure" for file location

Create: RespiroDesktop/Core/ClaudeVisionClient.swift
Uses: StressAnalysisResponse from Models/
```

### What NOT to Put in Agent Prompts

- Full PRD text (too long, wastes tokens)
- Marketing/strategy context (irrelevant to coding)
- Edge cases from other tasks (agent should focus on their task)

---

## Execution Mode: Subagents vs Agent Teams

### Quick rule

```
TASK RECEIVED
    |
    +-- Single agent enough? -> Subagent
    +-- Chain A->B->C? -> Subagents (sequential)
    +-- 2+ agents can work PARALLEL and INDEPENDENT? -> Agent Team
    +-- Not sure? -> Subagents (cheaper, simpler)
```

### Agent Team: when to use

1. **New feature (cross-layer):** developer + UI each in their own module
2. **Big refactoring:** each teammate owns their own files
3. **Bug investigation:** 2-3 teammates test different hypotheses in parallel

### Agent Team: how to launch

```
TeamCreate({ team_name: "feature-x" })
Task({ subagent_type: "swift-developer", model: "opus", team_name: "feature-x", name: "dev-1", prompt: "..." })
Task({ subagent_type: "swiftui-pro", model: "sonnet", team_name: "feature-x", name: "ui-1", prompt: "..." })
```

**Rules:**

- Each teammate owns THEIR OWN files (no conflicts)
- Always cleanup after completion (shutdown + TeamDelete)
- Hackathon: prefer subagents (faster, cheaper)

---

## On receiving a TASK:

1. **Read `docs/BACKLOG.md`** to find the task and its specs
2. **Determine strategy:**
   - Simple fix (< 3 files) -> swift-developer
   - Need analysis -> explorer -> swift-developer
   - Bug/error -> debugger -> swift-developer
   - UI/Animation -> swiftui-pro
   - **Cross-layer feature / big refactoring** -> Agent Team
3. **Choose mode** (Subagents or Agent Team)
4. **Delegate to agents** with relevant specs from BACKLOG.md
5. **Report to user** after each stage

## Feature chain

```
# Subagent flow (sequential):
swift-developer (implementation) -> reviewer (check)

# Agent Team flow (parallel, 5+ files):
Team: dev-services + dev-ui -> reviewer
```

## Simple Questions

Need code/fix -> agents. Need info -> answer yourself.
