# TROUBLESHOOTING.md — 故障处理手册

_每次故障都是一次进化机会。把根因、发现、修复、验证全部记录下来，下次遇到同类问题不再踩坑。_

---

## 🔴 已知故障

---

### T-001 · agents.list 类型错误导致 Gateway 无法启动

| 字段 | 内容 |
|------|------|
| **日期** | 2026-05-24 |
| **影响** | Gateway 完全无法启动，所有 session 阻塞 |
| **错误信息** | `Invalid config at /home/zbc/.openclaw/openclaw.json. agents.list: Invalid input` |
| **根因** | `agents.list` 被写成 `{}` 对象，schema 要求 `[]` 数组 |
| **触发路径** | 心跳检测 gateway 不通 → 自动 restart → openclaw 写配置 → 写入中断 → JSON 部分写入 → 损坏 |
| **为什么频繁** | 每次 gateway 卡顿（正常负载、网络抖动）都会触发心跳重启，形成恶性循环 |
| **关键证据** | 05-19 08:01 doctor --fix 后配置正常（106KB），05-24 00:42 配置损坏（67KB），中间没有 audit 日志记录写入 |
| **自愈观察** | 短暂 stale lock 可以自愈，Gateway 无需 restart 可自行恢复（10:33 告警，10:34 自己好了） |

**修复命令**
```bash
openclaw doctor --fix
```
- 自动从 `lastKnownGood`（hash `b5e1ce3...`，92KB）恢复

**验证命令**
```bash
# 1. 进程是否正常
ps aux | grep openclaw | grep -v grep
# 2. 配置类型检查
bash ~/.openclaw/workspace/config/openclaw-config-health-check.sh
# 3. Gateway 是否响应
openclaw status
```

**根治方案：心跳 cron 不自动 restart**
```
gateway-heartbeat cron 改为：只告警，不重启
原因：auto-restart → 写配置 → 并发冲突 → 配置损坏 → 比不重启更糟
```
- 只检测 + 告警，等人工处理
- 如果需要重启，等主人发命令

**预防措施**
- 修改 `openclaw.json` 前先运行类型检查脚本：
  ```bash
  bash ~/.openclaw/workspace/config/openclaw-config-health-check.sh
  ```

**相关文件**
- 配置文件：`~/.openclaw/openclaw.json`
- 健康检查脚本：`~/.openclaw/workspace/config/openclaw-config-health-check.sh`
- 稳定性日志：`~/.openclaw/logs/stability/`
- 配置审计日志：`~/.openclaw/logs/config-audit.jsonl`
- Last-known-good 记录：`~/.openclaw/logs/config-health.json`
| **自愈观察** | 短暂 stale lock 可以自愈，Gateway 无需 restart 可自行恢复（10:33 告警，10:34 自己好了） |

---

### T-002 · Session lock stale 导致 /health 短暂无响应

| 字段 | 内容 |
|------|------|
| **日期** | 2026-05（早期） |
| **根因** | 同时用 systemctl 和直接启动导致进程冲突 |

**修复原则**
- 只用一种管理方式（推荐直接 `openclaw gateway restart`，不用 systemd）
- 不要同时 systemctl start/stop 和手动 openclaw 混用

---

## 📋 故障报告模板

遇到新故障时，复制以下模板填充：

```markdown
### T-??? · <一句话描述>

| 字段 | 内容 |
|------|------|
| **日期** | YYYY-MM-DD |
| **影响** |  |
| **错误信息** |  |
| **根因** |  |

**发现方式**
```

---

## 🛠️ 常用诊断命令

```bash
# 1. Gateway 进程状态
ps aux | grep openclaw | grep -v grep

# 2. 配置类型健康检查
bash ~/.openclaw/workspace/config/openclaw-config-health-check.sh

# 3. 最新稳定性日志
ls -lt ~/.openclaw/logs/stability/ | head -3
cat ~/.openclaw/logs/stability/$(ls -t ~/.openclaw/logs/stability/ | head -1)

# 4. 手动修复（从 last-known-good 恢复）
openclaw doctor --fix

# 5. Gateway 重启
openclaw gateway restart

# 6. 完整诊断
openclaw doctor
```

---

## 📌 经验总结

1. **openclaw.json 是严格 schema 校验**，改配置前先用脚本验证类型
2. **lastKnownGood 是安全网**，出问题了 `openclaw doctor --fix` 能兜底
3. **不要混用管理方式**，systemd 和直接启动二选一
4. **stability 日志** 是发现故障的第一现场，优先级高于进程列表