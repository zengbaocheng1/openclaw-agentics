---
name: systematic-debugging
description: 4-phase root cause process before any fix. Use whenever you encounter an error.
---

# Systematic Debugging

Never guess at fixes. Find the root cause first.

## Phase 1: Understand the Error
- Read the full error message
- Note the exact file, line, error type
- Reproduce the error reliably
- Write: 'The error is: [exact error] at [location] when [trigger].'

## Phase 2: Hypothesize
Generate at least 2 hypotheses. For each: what evidence supports it? What would disprove it?

## Phase 3: Test Hypotheses
Test each hypothesis with the minimum change to confirm or deny it.
- Add a log line, not a fix
- Test one variable at a time

## Phase 4: Fix and Verify
1. Write the fix
2. Verify the original error is gone
3. Verify no new errors
4. Add a test that would have caught this bug
