---
name: knowledge-learner
description: Autonomous knowledge learning from web pages or pasted text. Use when the user provides a URL or pastes text content and wants to learn/summarize/extract key points, or when the user says things like "学习这个网页", "帮我看看这篇文章讲了什么", "总结一下这段内容", "帮我记下来". Supports extracting, summarizing, and storing knowledge into memory for future recall.
---

# Knowledge Learner

自主学习技能——从网页或文字中提取、归纳知识点，并持久化保存。

## When to Use

Trigger when the user:
- Sends a URL and wants to learn from it
- Pastes text content and asks for summaries/key points
- Says "学习", "总结", "帮我记下", "看看这篇文章" etc.
- Wants to review previously saved knowledge

## Workflow

### 1. Receiving Content

Two input modes:

- **URL**: Use `web_fetch` to extract content, then process
- **Pasted text**: Process directly

### 2. Extracting Knowledge

After obtaining content, do:

1. Read the full content carefully
2. Identify key points, facts, insights, and actionable information
3. Structure the knowledge into a clear summary
4. Present the summary to the user for confirmation

### 3. Saving to Memory

Once confirmed by the user, save to `memory/knowledge/` directory:

- File naming: `YYYY-MM-DD_<topic-slug>.md`
- Format: Markdown with metadata header
- Also update `MEMORY.md` if the knowledge is long-term important

File template:

```markdown
# <Topic Title>

- **Source**: <URL or "pasted text">
- **Date**: YYYY-MM-DD
- **Tags**: <comma-separated tags>

## Summary
<1-2 sentence overview>

## Key Points
- Point 1
- Point 2
- ...

## Details
<detailed notes>

## Actions / Takeaways
- <actionable items if any>
```

### 4. Retrieving Knowledge

User can ask to review saved knowledge:

- List all saved entries: `ls memory/knowledge/`
- Search by topic: `grep -rl "<keyword>" memory/knowledge/`
- Read specific entry: `read memory/knowledge/<filename>`

## Notes

- Always present the summary first and ask for confirmation before saving
- If content is very long, chunk it and process incrementally
- Tag each entry for easy future searching
- For technical content, include code snippets or formulas as relevant
- For Chinese content, keep summaries in Chinese; for English, keep in English
