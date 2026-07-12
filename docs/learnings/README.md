# OpenClaw 智能体 learnings

记录在日常运行中发现的技术经验、踩坑总结、最佳实践。

## 2026-05-23: OpenClaw 优化

### 模型配置清理
- NVIDIA provider 有大量 embed/coding 模型（nv-embed*, codegemma, codellama, granite 等）日常对话用不上，可移除
- OpenRouter 有虚假模型 ID（GPT-4.1/5.x 系列），上游根本不存在
- 模型 ID 格式：`provider/model-id`，查找时需注意不是只有 model-id
- 去重后模型数 483→289，Gateway 配置加载更快

### agents.list 格式错误
- `agents.list` 配置成了空 list，实际应为 dict
- 这类格式错误不影响启动但会导致某些功能异常

### Gateway 5/18 重启风暴
- 原因：systemd 和手动启动冲突，Gateway 已运行时再次启动会报 "already running"
- 解决：只用 systemd 管理，不要手动再启动

### Stability 日志
- `~/.openclaw/logs/stability/` 里的 JSON 文件是闪退记录
- 4/26 有 13 个 unhandled rejection（进程启动 32 秒后崩溃，原因不明）
- 5/18 有 6 个 stop_shutdown_timeout（session 清理超时）

## 2026-05-22: GitHub 项目创建

### 仓库规划
- openclaw-tools: 运维脚本集
- openclaw-recovery: 备份恢复脚本
- openclaw-agentics: 技能和工作流
- openclaw-web: FastAPI 管理界面

### 分支策略
- main: 稳定版
- dev: 开发版（新功能先在 dev 测试）

## 2026-05-23: 自学代理系统

### 设计
- 创建了 `self-learning-agent` cron 任务，每天凌晨3:00自动运行
- isolated agentTurn 模式，不占用主会话上下文
- 工作流：搜索GitHub → 对比已有 → 分析新项目 → 更新知识库 → commit到dev

### 关键设计决策
- `lightContext: true` 减少token消耗
- 不fork新仓库（避免版本碎片化）
- 只读分析，不修改本地配置
- 结果自动commit到openclaw-agentics dev分支
- 无新发现时静默（HEARTBEAT_OK）

### 完整的定时任务矩阵
| 时间 | 任务 | 频率 |
|------|------|------|
| 每15分钟 | gateway-heartbeat | 持续 |
| 03:00 | self-learning-agent | 每日 |
| 09:00 | daily-health-report | 每日 |

### 技能体系
- 39个技能覆盖安全/方法论/弹性/任务/自我改进
- 来源：openclaw-superpowers + 自研 + 社区
- 全部commit到openclaw-agentics dev分支

## 2026-05-24 — 自学循环
- 知识库: 24 个项目
- 技能: 43 个

## 2026-06-28 — 自学循环
- 知识库: 24 个项目
- 技能: 48 个

## 2026-07-05 — 自学循环
- 知识库: 24 个项目
- 技能: 49 个

## 2026-07-12 — 自学循环
- 知识库: 24 个项目
- 技能: 57 个
