# openclaw-superpowers - 56个即用技能

## 仓库
https://github.com/ArchieIndian/openclaw-superpowers | Fork: zengbaocheng1

## 价值
- 让智能体具备自主、自愈、自我改进能力
- 56个技能分3类：core(17) + openclaw-native(38) + community(1)

## Core 核心技能
| 技能 | 功能 |
|------|------|
| create-skill | 对话中写新技能，立即生效 |
| systematic-debugging | 4阶段根因分析 |
| writing-plans | 结构化计划 |
| executing-plans | 分步执行+验证 |
| test-driven-development | 红绿重构 |
| fact-check-before-trust | 事实核查 |
| skill-vetting | 技能安全扫描 |
| skill-conflict-detector | 技能冲突检测 |

## OpenClaw-Native 自主运维技能
| 技能 | 功能 |
|------|------|
| agent-self-recovery | 崩溃自恢复 |
| persistent-memory-hygiene | 记忆清理 |
| heartbeat-governor | 心跳治理 |
| prompt-injection-guard | 提示注入防护 |
| dangerous-action-guard | 危险操作拦截 |
| secrets-hygiene | 密钥扫描 |
| config-encryption-auditor | 配置加密审计 |
| spend-circuit-breaker | 花费熔断 |
| context-budget-guard | 上下文预算控制 |
| large-file-interceptor | 大文件拦截 |
| loop-circuit-breaker | 循环断路器 |
| morning-briefing | 每日早报 |
| community-skill-radar | 社区需求扫描 |

## 安装
```bash
git clone https://github.com/ArchieIndian/openclaw-superpowers ~/.openclaw/extensions/superpowers
cd ~/.openclaw/extensions/superpowers && ./install.sh
openclaw gateway restart
```
