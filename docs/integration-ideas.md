# OpenClaw 能力扩展集成计划

## 高优先级（可立即利用）

### 1. Lobster 工作流引擎
- **价值**：省 token、提升自动化可靠性、支持 pipeline resume
- **集成方式**：安装 lobster，将复杂任务写成 workflow 文件
- **应用场景**：
  - GitHub PR 监控（自动检查状态变化）
  - 定时任务编排（health-check → alert → auto-fix）
  - 多步骤审批流程

### 2. Peekaboo 截图
- **价值**：视觉问答、环境感知
- **集成方式**：安装后通过 exec 调用
- **应用场景**：
  - 帮我看看桌面现在的状态
  - 截图 + 问问题

### 3. mcporter (MCP客户端)
- **价值**：连接更多 MCP 服务
- **集成方式**：调用其他 MCP 服务器
- **应用场景**：
  - 连接文件系统 MCP
  - 连接数据库 MCP

## 中优先级

### 4. imsg / wacli
- **价值**：多渠道消息收发
- **注意**：需要 macOS/iOS

### 5. gogcli (Google Workspace)
- **价值**：Gmail/Drive/Sheets 自动化
- **应用场景**：邮件总结、日程管理、文档处理

## 低优先级（环境限制）

### 6. openclaw-ansible
- **价值**：生产环境自动化部署
- **前提**：需要多台服务器

## 行动项
- [ ] 安装 lobster 并测试工作流
- [ ] 安装 peekaboo 并测试截图
- [ ] 编写第一个 lobster workflow
