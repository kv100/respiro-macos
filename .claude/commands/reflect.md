---
description: Generate session reflection and update memory
---

<objective>
Create structured session reflection capturing decisions and lessons learned.
</objective>

<process>
1. Run `git diff HEAD~5..HEAD --stat` to see recent changes
2. Run `git log --oneline -10` for recent commits
3. Analyze what was accomplished in this session
4. Create reflection file in `.claude/reflections/YYYY-MM-DD-{gist}.md`
5. Add 1-liner summary to `.claude/archive/SESSIONS.md`
6. **Update `docs/BACKLOG.md`** — mark [x] for all completed tasks
7. Update `.claude/STATE.md` if needed
</process>

<template>
# Session: {DATE} — {TITLE}

## Accomplished

- [List of completed tasks]

## Decisions Made

| Decision | Rationale |
| -------- | --------- |
| X        | Y         |

## Technical Notes

- [Key technical details]

## Next Session

- Continue with: [task]
  </template>

<output>
After generating reflection:
1. Confirm file created in `.claude/reflections/`
2. Show SESSIONS.md update
3. Confirm BACKLOG.md checkboxes updated
4. Confirm STATE.md updated
</output>
