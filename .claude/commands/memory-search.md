---
description: Search past sessions and learnings by keyword
---

<objective>
Find relevant context from past sessions when working on similar tasks.
</objective>

<usage>
/memory-search {keyword}

Examples:

- /memory-search RevenueCat
- /memory-search Metal fps
- /memory-search auth linking
  </usage>

<process>
1. Search LEARNINGS.md for keyword
2. Search reflections/*.md for keyword (grep)
3. Search SESSIONS.md for keyword
4. Present findings grouped by source
</process>

<execution>
```bash
# Search learnings
grep -i "{keyword}" .claude/LEARNINGS.md

# Search reflections (with context)

grep -ri "{keyword}" .claude/reflections/ -l | head -5

# Search sessions archive

grep -i "{keyword}" .claude/archive/SESSIONS.md

```
</execution>

<output>
## Memory Search: {keyword}

### From LEARNINGS.md
[Matching lines with context]

### From Reflections
[List of relevant reflection files with dates]
- Read most relevant 1-2 for full context

### From Sessions Archive
[Matching session summaries]

### Recommendation
[Which file to read for more context]
</output>
```
