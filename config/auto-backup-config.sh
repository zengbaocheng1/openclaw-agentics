#!/bin/bash
# auto-backup-config.sh
# 每天凌晨检查 openclaw.json 是否有修改，有则自动备份

CONFIG="$HOME/.openclaw/openclaw.json"
BACKUP_DIR="$HOME/.openclaw/workspace/config/backup"
HASH_FILE="$BACKUP_DIR/.last-hash"
RETENTION=7

# 确保备份目录存在
mkdir -p "$BACKUP_DIR"

# 读取上次 hash
LAST_HASH=""
if [ -f "$HASH_FILE" ]; then
    LAST_HASH=$(cat "$HASH_FILE")
fi

# 计算当前 hash
CURRENT_HASH=$(sha256sum "$CONFIG" | cut -d' ' -f1)

# 无变化，不备份
if [ "$CURRENT_HASH" == "$LAST_HASH" ]; then
    echo "no-change"
    exit 0
fi

# 有变化，开始备份
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_SUBDIR="$BACKUP_DIR/$TIMESTAMP"
mkdir -p "$BACKUP_SUBDIR"

# 备份核心配置
cp "$CONFIG" "$BACKUP_SUBDIR/openclaw.json"

# 备份所有配置文件
cp "$HOME/.openclaw/gateway-owner.json" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/exec-approvals.json" "$BACKUP_SUBDIR/" 2>/dev/null

# 备份 workspace 关键文件
cp "$HOME/.openclaw/workspace/AGENTS.md" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/workspace/SOUL.md" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/workspace/MEMORY.md" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/workspace/TROUBLESHOOTING.md" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/workspace/IDENTITY.md" "$BACKUP_SUBDIR/" 2>/dev/null
cp "$HOME/.openclaw/logs/config-health.json" "$BACKUP_SUBDIR/" 2>/dev/null

# 记录当前 hash
echo "$CURRENT_HASH" > "$HASH_FILE"

# 生成 manifest
cat > "$BACKUP_SUBDIR/manifest.txt" << EOF
Auto-backup time: $(date)
Gateway PID: $(pgrep -f openclaw | head -1)
Config hash: $CURRENT_HASH
Config size: $(wc -c < "$CONFIG") bytes
EOF

# 滚动清理，保留最近 $RETENTION 份
cd "$BACKUP_DIR" || exit 1
TOTAL=$(ls -d 20* 2>/dev/null | wc -l)
if [ "$TOTAL" -gt "$RETENTION" ]; then
    ls -dt 20* | tail -$((TOTAL - RETENTION)) | xargs rm -rf 2>/dev/null
fi

echo "backed-up:$TIMESTAMP:$CURRENT_HASH"