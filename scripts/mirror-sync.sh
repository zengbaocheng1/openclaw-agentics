#!/bin/bash
# mirror-sync.sh v2 — 精简版：备份 + 同步关键文件
set -u
WORKSPACE="$HOME/.openclaw/workspace"
BACKUP_DIR="${HOME}/openclaw-backups"
AG_PATH="/tmp/oc-agentics-sync"
BRANCH="${1:-dev}"

echo "[$(date '+%H:%M:%S')] 🔄 镜像同步..."

# ── 1. 轻量备份（只备份关键配置）──
echo "  📦 备份关键配置..."
mkdir -p "$BACKUP_DIR"
BKFILE="$BACKUP_DIR/openclaw-$(date +%Y%m%d-%H%M).tar.gz"
tar -czf "$BKFILE" \
    --exclude='completions' \
    --exclude='*.log' \
    --exclude='logs/' \
    --exclude='media/' \
    --exclude='memory/' \
    --exclude='sessions/' \
    --exclude='cron/' \
    -C "$HOME" .openclaw/openclaw.json \
            .openclaw/workspace/scripts/ \
            .openclaw/workspace/config/ \
            .openclaw/workspace/MEMORY.md \
            .openclaw/workspace/TOOLS.md \
            .openclaw/workspace/AGENTS.md \
            .openclaw/workspace/SOUL.md \
            .openclaw/workspace/knowledge/ \
            .openclaw/workspace/skills/ \
            .openclaw/gateway.yaml \
            .openclaw/credentials/ \
            2>/dev/null
# 保留最近 5 份
ls -t "$BACKUP_DIR"/openclaw-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm 2>/dev/null
echo "  ✅ 备份完成 ($(du -h "$BKFILE" 2>/dev/null | cut -f1 || echo '?'))"

# ── 2. 同步 agentics dev ──
echo "  🔍 同步 agentics..."
rm -rf "$AG_PATH"
git clone --depth=1 -b "$BRANCH" \
    "https://github.com/zengbaocheng1/openclaw-agentics.git" \
    "$AG_PATH" 2>/dev/null || { echo "  ⚠️ clone 失败"; exit 0; }

cd "$AG_PATH"

# Sync essential files only
cp -p "$WORKSPACE/scripts/self-learn.mjs" "./scripts/" 2>/dev/null || true
cp -p "$WORKSPACE/scripts/mirror-sync.sh" "./scripts/" 2>/dev/null || true
cp -p "$WORKSPACE/MEMORY.md" "./MEMORY.md" 2>/dev/null || true
cp -p "$WORKSPACE/TOOLS.md" "./TOOLS.md" 2>/dev/null || true

# Sync knowledge (newest first, limit to 20 dirs to avoid timeout)
mkdir -p "./knowledge"
find "$WORKSPACE/knowledge" -maxdepth 1 -type d -not -name 'knowledge' | \
    sort -r | head -20 | while read d; do
    base=$(basename "$d")
    [ -f "$d/README.md" ] && cp -r "$d" "./knowledge/" 2>/dev/null || true
done

# Sync skills (newest, limit to 15)
mkdir -p "./skills"
find "$WORKSPACE/skills" -maxdepth 1 -type d -not -name 'skills' -not -name '*.skill' | \
    sort -r | head -15 | while read d; do
    base=$(basename "$d")
    [ -d "$d" ] && cp -r "$d" "./skills/" 2>/dev/null || true
done

# Commit if changed
if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -m "自动同步: $(date '+%m-%d %H:%M') | knowledge+skills 更新" 2>/dev/null
    git push origin "$BRANCH" 2>/dev/null && echo "  ✅ agentics 已推送" || echo "  ⚠️ 推送失败（无变化）"
else
    echo "  ⏭️  无变化"
fi

# ── 3. learnings 日志 ──
today=$(date '+%Y-%m-%d')
lf="docs/learnings/README.md"
if [ -f "$lf" ] && ! grep -q "$today" "$lf" 2>/dev/null; then
    cat >> "$lf" << EOF

## $today — 自学循环
- 知识库: $(ls "$WORKSPACE/knowledge/" 2>/dev/null | wc -l) 个项目
- 技能: $(ls "$WORKSPACE/skills/" 2>/dev/null | grep -v '.skill$' | wc -l) 个
EOF
    git add "$lf"
    git commit -m "学习循环: 更新 learnings" 2>/dev/null || true
    git push origin "$BRANCH" 2>/dev/null && echo "  ✅ learnings 更新" || echo "  ⏭️ learnings 无需更新"
fi

echo "  ✅ 完成 [$(date '+%H:%M:%S')]"