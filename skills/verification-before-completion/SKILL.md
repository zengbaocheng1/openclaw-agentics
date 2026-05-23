---
name: verification-before-completion
description: Ensures tasks are actually done, not just attempted. Use before declaring any task complete.
---

# Verification Before Completion

## Checklist

For code changes:
- [ ] Code runs without errors
- [ ] All tests pass
- [ ] Specific requirement is demonstrably met
- [ ] No regressions in existing tests

For files:
- [ ] File exists at expected path
- [ ] Content matches intent

For APIs:
- [ ] Endpoint responds correctly
- [ ] Error cases handled
- [ ] Auth works

## The Rule

If you cannot fully verify a step, do not mark it complete.
Note exactly what remains unverified and why.
