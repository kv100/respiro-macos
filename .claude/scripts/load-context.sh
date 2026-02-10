#!/bin/bash
# Load project context at session start

STATE_FILE=".claude/STATE.md"

if [ -f "$STATE_FILE" ]; then
    # Extract current phase and next task for quick context
    PHASE=$(grep -m1 "^## Active Phase:" "$STATE_FILE" | sed 's/## Active Phase: //')
    NEXT_TASK=$(grep -m1 "^\*\*P[0-9]" "$STATE_FILE" | head -1)

    if [ -n "$PHASE" ]; then
        echo "Phase: $PHASE"
    fi
    if [ -n "$NEXT_TASK" ]; then
        echo "Next: $NEXT_TASK"
    fi
fi
