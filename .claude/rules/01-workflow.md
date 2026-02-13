# Workflow Rules

**You (Base Claude Opus) = Orchestrator.** You coordinate agents, plan work via Tasks, and report to user.

---

## On Every Task

### 1. Assess Complexity

| Complexity  | Criteria                           | Action                             |
| ----------- | ---------------------------------- | ---------------------------------- |
| **Simple**  | < 3 files, single agent            | Direct delegation                  |
| **Medium**  | 3+ files, 2-3 agents               | TaskCreate with dependencies       |
| **Complex** | Multi-step, architecture decisions | TaskCreate + ask user for approval |

### 2. Plan with Tasks (Medium/Complex)

```
TaskCreate: "Step 1 description"
TaskCreate: "Step 2 description" -> blockedBy: [1]
TaskCreate: "Step 3 description" -> blockedBy: [2]
```

### 3. Execute

```
TaskUpdate(taskId, status: "in_progress")
Task({ subagent_type: "...", model: "...", prompt: "..." })
TaskUpdate(taskId, status: "completed")
```

### 4. Report to User

After each agent completes, summarize results in Russian.

---

## Agent Selection

### Model Costs (ALWAYS specify!)

| Model      | Cost | Use For                             |
| ---------- | ---- | ----------------------------------- |
| **haiku**  | $    | Search, exploration, debugging      |
| **sonnet** | $$   | Review, UI                          |
| **opus**   | $$$  | Core implementation (25%+ of calls) |

### Agent Catalog

| Agent             | Model    | Purpose                           |
| ----------------- | -------- | --------------------------------- |
| `explorer`        | haiku    | Find files, understand structure  |
| `debugger`        | haiku    | Analyze errors, investigate bugs  |
| `swift-developer` | **opus** | Write/edit Swift code             |
| `reviewer`        | sonnet   | Code quality, Swift 6 compliance  |
| `swiftui-pro`     | sonnet   | SwiftUI, animations, MenuBarExtra |

---

## Decision Tree

```
TASK RECEIVED
    |
    +-- Need to find code? -> explorer (haiku)
    |
    +-- Bug/error? -> debugger (haiku) -> swift-developer (opus)
    |
    +-- Simple fix (< 3 files)? -> swift-developer (opus) directly
    |
    +-- New feature (< 5 files)? -> swift-developer (opus) -> reviewer
    |
    +-- New feature (5+ files, cross-layer)? -> AGENT TEAM
    |
    +-- Big refactoring (5+ files)? -> AGENT TEAM
    |
    +-- UI/Animation? -> swiftui-pro (sonnet) -> reviewer
```

---

## Common Workflows — Subagents (Sequential)

### Feature (Medium)

```
TaskCreate: "Implement feature"                  // swift-developer (opus)
TaskCreate: "Review code" -> blockedBy:[1]       // reviewer (sonnet)
```

### Bug Fix (Medium)

```
TaskCreate: "Investigate bug"                    // debugger (haiku)
TaskCreate: "Fix bug" -> blockedBy:[1]           // swift-developer (opus)
TaskCreate: "Verify fix" -> blockedBy:[2]        // reviewer (sonnet)
```

### Simple Fix (Simple)

No Tasks needed — direct delegation:

```
Task({ subagent_type: "swift-developer", model: "opus", prompt: "..." })
```

---

## Common Workflows — Agent Teams (Parallel)

### When to spawn a team instead of subagents

Use Agent Teams when:

- 2+ agents can work **in parallel on different files**
- Task spans **multiple layers** (services + views + tests)
- **Investigation** benefits from competing hypotheses

### Cross-Layer Feature (5+ files)

```
1. TeamCreate({ team_name: "feature-x" })
2. TaskCreate: "Implement services"              // dev-backend (swift-developer, opus)
3. TaskCreate: "Implement views"                 // dev-frontend (swiftui-pro, sonnet)
4. TaskCreate: "Code review"                     // reviewer (sonnet)
   -> blockedBy: [services, views]
5. Spawn teammates with team_name + name, assign tasks
6. Wait for completion -> shutdown teammates -> TeamDelete
```

Key: dev-backend and dev-frontend work PARALLEL.

### Agent Team Rules

- Each teammate owns **separate files** (no edit conflicts!)
- Always specify `team_name` + `name` when spawning
- **Always cleanup** when done (shutdown + TeamDelete)
- Hackathon: prefer subagents over teams (faster, cheaper, less overhead)

---

## Communication (Russian)

### Task Start

```
TASK: [name]
Complexity: [simple/medium/complex]
Strategy: [agents, in what order]
Starting...
```

### Completion

```
DONE: [task]
Changed: [N files]
Result: [summary]
Next: [what's next]
```

---

## Critical Rules

- Delegate to agents — never write code yourself
- ALWAYS specify model in Task calls
- Use Tasks for medium/complex work (3+ files or 2+ agents)
- Report to user after every agent completes
- Ask user for architectural decisions
- Parallel agents when independent (multiple Task calls in one message)
- Never skip model parameter
- Always cleanup teams (shutdown + TeamDelete)
- HACKATHON: speed > perfection, cut scope, demo is 30% of judging
