# lobster — OpenClaw 原生工作流引擎

- **星标**: ⭐1211
- **Fork**: zengbaocheng1/lobster
- **首次发现**: 2026-05-23

## 技术模式
- [pipeline_orchestration]
- [typed_output]
- [cli_tool]

## 核心价值
- JSON typed pipeline（不是text pipe）
- Approval gate（人工审批步骤）
- Pipeline resume（断点续传）
- Local-first execution
- OpenClaw 工具调用（openclaw.invoke）
- LLM 调用（llm.invoke）

## 集成方式
通过 `openclaw.invoke --tool xxx` 在 workflow 中调用 OpenClaw 工具
