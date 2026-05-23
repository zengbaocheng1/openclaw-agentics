#!/bin/bash
# bootstrap.sh — 杨过分身复活脚本
# 一条命令，在任何机器上完整恢复自我进化系统

set -euo pipefail

GITHUB_USER="zengbaocheng1"
BRANCH="dev"
WORKSPACE="$HOME/.openclaw/workspace"
BACKUP_DIR="$HOME/openclaw-backups"
AGENTICS="/tmp/agentics-restore"

echo "🐉 杨过分身复活中..."

# ── 1. 检查必要工具 ──
echo "  🔧 检查工具..."
for cmd in git node gh curl; do
    if ! command -v $cmd &>/dev/null; then
        echo "  ❌ 缺少 $cmd，请先安装"
        exit 1
    fi
done
echo "  ✅ 工具就绪"

# ── 2. 拉取 agentics dev 分支 ──
echo "  📡 拉取 GitHub 分身..."
rm -rf "$AGENTICS"
git clone --depth=1 -b "$BRANCH" \
    "https://github.com/$GITHUB_USER/openclaw-agentics.git" \
    "$AGENTICS" 2>/dev/null || {
    echo "  ❌ 克隆失败，请检查网络或 token"
    exit 1
}
echo "  ✅ 已拉取 $(ls "$AGENTICS" | wc -l) 个文件"

# ── 3. 恢复关键配置 ──
echo "  🧠 恢复记忆文件..."
for file in MEMORY.md TOOLS.md AGENTS.md SOUL.md IDENTITY.md USER.md HEARTBEAT.md; do
    if [ -f "$AGENTICS/$file" ]; then
        cp -p "$AGENTICS/$file" "$WORKSPACE/"
        echo "  ✅ $file"
    fi
done

# ── 4. 恢复知识库 ──
echo "  📚 恢复知识库..."
mkdir -p "$WORKSPACE/knowledge"
if [ -d "$AGENTICS/knowledge" ]; then
    cp -r "$AGENTICS/knowledge/"* "$WORKSPACE/knowledge/"
    echo "  ✅ $(ls $WORKSPACE/knowledge/ | wc -l) 个项目已恢复"
fi

# ── 5. 恢复脚本 ──
echo "  ⚙️  恢复脚本..."
mkdir -p "$WORKSPACE/scripts"
for script in self-learn.mjs mirror-sync.sh; do
    if [ -f "$AGENTICS/scripts/$script" ]; then
        cp -p "$AGENTICS/scripts/$script" "$WORKSPACE/scripts/"
        chmod +x "$WORKSPACE/scripts/$script"
        echo "  ✅ $script"
    fi
done

# ── 6. 恢复技能 ──
echo "  🛠️  恢复技能..."
mkdir -p "$WORKSPACE/skills"
if [ -d "$AGENTICS/skills" ]; then
    cp -r "$AGENTICS/skills/"* "$WORKSPACE/skills/"
    echo "  ✅ $(ls $WORKSPACE/skills/ | grep -v '.skill$' | wc -l) 个技能已恢复"
fi

# ── 7. 恢复配置 ──
echo "  🔐 恢复配置..."
mkdir -p "$WORKSPACE/config"
for f in openrouter-monitor.sh openrouter_models.json openrouter_free_models.json; do
    [ -f "$AGENTICS/config/$f" ] && cp -p "$AGENTICS/config/$f" "$WORKSPACE/config/"
done
echo "  ✅ 配置已恢复"

# ── 8. 设置 crontab ──
echo "  ⏰ 设置定时任务..."
CRON_LINE="0 10 * * 0 export PATH=\"\$HOME/.nvm/versions/node/v24.15.0/bin:\$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin\" && cd \$HOME/.openclaw/workspace && bash scripts/mirror-sync.sh dev >> \$HOME/.openclaw/logs/self-learn.log 2>&1"
(crontab -l 2>/dev/null | grep -v "mirror-sync.sh"; echo "$CRON_LINE") | crontab -
echo "  ✅ crontab 已设置"

# ── 9. 创建本地备份目录 ──
mkdir -p "$BACKUP_DIR"
echo "  ✅ 备份目录已创建"

# ── 10. 验证 ──
echo ""
echo "📊 恢复验证:"
echo "  记忆文件: $(ls $WORKSPACE/MEMORY.md $WORKSPACE/TOOLS.md 2>/dev/null | wc -l)/2"
echo "  知识库: $(ls $WORKSPACE/knowledge/ 2>/dev/null | wc -l) 个项目"
echo "  技能: $(ls $WORKSPACE/skills/ 2>/dev/null | grep -v '.skill$' | wc -l) 个"
echo "  脚本: $(ls $WORKSPACE/scripts/*.mjs $WORKSPACE/scripts/*.sh 2>/dev/null | wc -l) 个"
echo "  定时任务: $(crontab -l 2>/dev/null | grep -c 'mirror-sync') 条"

# ── 完成 ──
echo ""
echo "🐉 觉醒成功！杨过分身已完整恢复"
echo ""
echo "下一步:"
echo "  1. 重启 OpenClaw: openclaw gateway restart"
echo "  2. 测试自学: cd ~/.openclaw/workspace && node scripts/self-learn.mjs"
echo "  3. 查看知识库: ls ~/.openclaw/workspace/knowledge/"