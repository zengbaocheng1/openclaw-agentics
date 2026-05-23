---
name: executing-plans
description: Executes plans task-by-task with verification. Use when implementing a plan.
---

# Executing Plans

## The Loop

For each step:
1. Read the step carefully
2. Do exactly what the step says
3. Verify the step is complete
4. Mark it done: [x]
5. Continue to next step

## Rules

- Stay on task. Note other issues, do not fix them mid-step.
- Verify before continuing. 'I think that worked' is not verification.
- Handle failures explicitly. Stop and diagnose before retrying.

## OpenClaw Checkpointing

At checkpoint steps, update memory/YYYY-MM-DD.md with:
- Which steps are done
- Current state of the work
- Any decisions made
- Next step to resume from
