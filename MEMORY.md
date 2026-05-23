# MEMORY.md — 长期记忆

## 📚 已学项目

### 官方工具
- **openclaw/lobster** (⭐1211): 工作流引擎 — JSON typed pipeline, approval gate, pipeline resume
- **openclaw/Peekaboo** (⭐4439): 截图+VQA视觉问答 — CLI↔MCP双模式
- **openclaw/mcporter** (⭐4483): MCP客户端 — TypeScript调用，可包装为CLI
- **openclaw/gogcli** (⭐7516): Google Workspace CLI — stdout=JSON/stderr=人类提示
- **openclaw/wacli** (⭐2450): WhatsApp CLI — "不该用时不用"安全约束
- **openclaw/imsg** (⭐1124): iMessage CLI — 本地优先
- **openclaw/clawhub** (⭐8726): 技能目录 — 所有官方技能集合
- **openclaw/openclaw-ansible** (⭐581): 自动化部署
- **openclaw/nix-openclaw** (⭐692): Nix包管理

### 社区资源
- **ArchieIndian/openclaw-superpowers** (⭐56 skills): 自主/自愈/安全/自我改进技能库
- **VoltAgent/awesome-openclaw-skills** (5400+ skills): 全部技能索引
- **LeoYeAI/openclaw-master-skills** (1209+ skills): 每周更新的精选技能
- **vincentkoc/awesome-openclaw**: 技术栈推荐
- **alvinreal/awesome-openclaw**: 资源列表

## 📚 待学项目
（自学代理自动填充）

## 🧠 学到的最佳实践
- 模型配置去重：483→289，精简约40%
- agents.list 必须是 dict 而非 list
- Gateway 重启风暴：systemd冲突，只用一种管理方式
- 技能应从 superpowers 精选安装，不要全量（可能有cron冲突）
- 工具模式：stdout=JSON用于程序管道，stderr=人类可读用于调试
- [ ] **NousResearch/hermes-agent** (⭐163286): The agent that grows with you — https://github.com/NousResearch/hermes-agent
- [ ] **farion1231/cc-switch** (⭐78296): A cross-platform desktop All-in-One assistant for Claude Code, Codex, OpenCode, OpenClaw, Gemini CLI & Hermes Agent. Only official website: ccswitch.io — https://github.com/farion1231/cc-switch
- [ ] **thedotmack/claude-mem** (⭐77525): Persistent Context Across Sessions for Every Agent –  Captures everything your agent does during sessions, compresses it with AI, and injects relevant context back into future sessions. Works with Claude Code, OpenClaw, Codex, Gemini, Hermes, Copilot, OpenCode + More — https://github.com/thedotmack/claude-mem
- [ ] **safishamsi/graphify** (⭐51904): AI coding assistant skill (Claude Code, Codex, OpenCode, Cursor, Gemini CLI, and more). Turn any folder of code, SQL schemas, R scripts, shell scripts, docs, papers, images, or videos into a queryable knowledge graph. App code + database schema + infrastructure in one graph. — https://github.com/safishamsi/graphify
- [ ] **CherryHQ/cherry-studio** (⭐46123): AI productivity studio with smart chat, autonomous agents, and 300+ assistants. Unified access to frontier LLMs — https://github.com/CherryHQ/cherry-studio
- [ ] **zhayujie/CowAgent** (⭐44725): CowAgent (chatgpt-on-wechat) 是基于大模型的超级AI助理，能主动思考和任务规划、访问操作系统和外部资源、创造和执行Skills、通过长期记忆和知识库不断成长，比OpenClaw更轻量和便捷。同时支持微信、飞书、钉钉、企微、QQ、公众号、网页等接入，可选择DeepSeek/OpenAI/Claude/Gemini/ MiniMax/Qwen/GLM/LinkAI，能处理文本、语音、图片和文件，可快速搭建个人AI助理和企业数字员工。 — https://github.com/zhayujie/CowAgent
- [ ] **siyuan-note/siyuan** (⭐44069): A privacy-first, self-hosted, fully open source personal knowledge management software, written in typescript and golang. — https://github.com/siyuan-note/siyuan
- [ ] **HKUDS/nanobot** (⭐43011): Lightweight, open-source AI agent for your tools, chats, and workflows. — https://github.com/HKUDS/nanobot
- [ ] **moeru-ai/airi** (⭐39459): 💖🧸 Self hosted, you-owned Grok Companion, a container of souls of waifu, cyber livings to bring them into our worlds, wishing to achieve Neuro-sama's altitude. Capable of realtime voice chat, Minecraft, Factorio playing. Web / macOS / Windows supported. — https://github.com/moeru-ai/airi
- [ ] **1Panel-dev/1Panel** (⭐35548): 🔥 1Panel is a modern, open-source VPS control panel — and the only one with native AI agent support. Run Ollama models, deploy OpenClaw agents, and manage your entire server stack from one clean web interface. — https://github.com/1Panel-dev/1Panel
- [ ] **AstrBotDevs/AstrBot** (⭐32874): AI Agent Assistant & development framework that integrates lots of IM platforms, LLMs, plugins and AI feature, and can be your openclaw alternative. ✨ — https://github.com/AstrBotDevs/AstrBot
- [ ] **kepano/obsidian-skills** (⭐32528): Agent skills for Obsidian. Teach your agent to use Markdown, Bases, JSON Canvas, and use the CLI. — https://github.com/kepano/obsidian-skills
- [ ] **zeroclaw-labs/zeroclaw** (⭐31535): Fast, small, and fully autonomous AI personal assistant infrastructure, any OS, any platform — deploy anywhere, swap anything 🦀 — https://github.com/zeroclaw-labs/zeroclaw
- [ ] **hesamsheikh/awesome-openclaw-usecases** (⭐31152): A community collection of OpenClaw use cases for making life easier. — https://github.com/hesamsheikh/awesome-openclaw-usecases
- [ ] **nanocoai/nanoclaw** (⭐29286): A lightweight alternative to OpenClaw that runs in containers for security. Connects to WhatsApp, Telegram, Slack, Discord, Gmail and other messaging apps,, has memory, scheduled jobs, and runs directly on Anthropic's Agents SDK — https://github.com/nanocoai/nanoclaw
- [ ] **Alishahryar1/free-claude-code** (⭐28081): Use claude-code for free in the terminal, VSCode extension or discord like OpenClaw (voice supported) — https://github.com/Alishahryar1/free-claude-code
- [ ] **mvanhorn/last30days-skill** (⭐26361): AI agent skill that researches any topic across Reddit, X, YouTube, HN, Polymarket, and the web - then synthesizes a grounded summary — https://github.com/mvanhorn/last30days-skill
- [ ] **iOfficeAI/AionUi** (⭐26196): Free, local, open-source 24/7 Cowork app for OpenClaw, Hermes Agent, Claude Code, Codex, OpenCode, Gemini CLI and 20+ more CLI | Customize your assistants | Star if you like it! — https://github.com/iOfficeAI/AionUi
- [ ] **volcengine/OpenViking** (⭐24525): OpenViking is an open-source context database designed specifically for AI Agents(such as openclaw). OpenViking unifies the management of context (memory, resources, and skills) that Agents need through a file system paradigm, enabling hierarchical context delivery and self-evolving. — https://github.com/volcengine/OpenViking
- [ ] **NVIDIA/NemoClaw** (⭐20605): Run OpenClaw more securely inside NVIDIA OpenShell with managed inference — https://github.com/NVIDIA/NemoClaw
- [ ] **garrytan/gbrain** (⭐18240): Garry's Opinionated OpenClaw/Hermes Agent Brain — https://github.com/garrytan/gbrain
