# OpenClaw-RL (Gen-Verse/OpenClaw-RL)

## 仓库
https://github.com/Gen-Verse/OpenClaw-RL

## 价值
通过强化学习让 OpenClaw 从日常对话中自我进化——用户只需正常聊天，模型就能持续优化。这是第一个将个性化 RL 训练无缝集成到 OpenClaw 使用流程中的开源框架。

## 功能

**核心能力**：
- 完全异步 RL 框架，将 Agent 服务、Rollout 收集、PRM/Judge 评估、策略训练解耦为独立组件，互不阻塞
- 零人工标注，自动将多轮对话整理为训练轨迹
- 支持三种学习范式：Binary RL (GRPO)、On-Policy Distillation (OPD)、Hybrid（混合）
- 支持 LoRA 训练，支持 Qwen3.5-4B/9B/27B 多尺度模型
- 支持本地 GPU + 云端（Tinker/Fireworks AI）部署

**扩展场景（Track 2）**：
- Terminal Agent RL
- GUI Agent RL
- SWE Agent RL
- Tool-call Agent RL

## 关键文件
- `openclaw-combine/` — Hybrid RL 训练方法（Binary RL + OPD 结合）
- `openclaw-opd/` — On-Policy Distillation 实现
- `extensions/rl-training-headers/` — OpenClaw 扩展，可在自有实例上启用 RL 训练
- `slime/` — 底层 RL 框架

## 技术报告
arXiv:2603.10165，发布首日即登 HuggingFace Daily Papers #1

## 用途
- 为个人 OpenClaw 实例注入 RL 训练能力，从对话反馈中持续优化模型表现
- 构建专用 Agent（Terminal/GUI/SWE/Tool-call）的可扩展 RL 训练流水线
- 企业私有化 Agent 个性化训练，无需上传数据到第三方