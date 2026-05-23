---
name: subagent-driven-development
description: Parallel subagent execution for complex tasks. Use when a task has independent parallel workstreams.
---

# Subagent-Driven Development

## When to Use

- Task has 2+ independent workstreams
- Each workstream takes >10 minutes
- Workstreams do not share mutable state

## The Pattern

1. **Decompose** - break into independent subtasks
2. **Spec each subagent** - clear, self-contained instructions
3. **Launch in parallel** - use exec with background:true
4. **Monitor** - check progress, do not micromanage
5. **Integrate** - run full test suite after all complete

## Launch Pattern

```
exec command:"claude --permission-mode bypassPermissions --print '[spec A]'" background:true
exec command:"claude --permission-mode bypassPermissions --print '[spec B]'" background:true
```
