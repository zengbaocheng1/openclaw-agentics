# Lobster - OpenClaw 原生工作流引擎

## 价值
- 将多个工具/技能组合成**typed pipeline**，省 token + 更可靠
- 支持**approval gate**（人工审批步骤）
- 支持**pipeline resume**（断点续传）
- 支持 OpenClaw 工具调用（openclaw.invoke）
- 支持 LLM 调用（llm.invoke）

## 核心文件
- `bin/lobster.js` - 入口
- `src/runtime.ts` - 运行时
- `src/cli.ts` - CLI 命令
- `src/parser.ts` - 工作流解析
- `src/recipes/` - 工作流模板

## 使用方式
```bash
lobster run workflow.yaml --args-json '{"key":"value"}'
lobster graph --file workflow.lobster --format mermaid
```

## 集成 OpenClaw
通过 `openclaw.invoke --tool xxx` 在 workflow 中调用 OpenClaw 工具
