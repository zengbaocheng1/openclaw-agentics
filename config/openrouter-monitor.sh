#!/bin/bash
# OpenRouter 免费模型监控脚本
# 用法: bash openrouter-monitor.sh [--notify]

SNAPSHOT="$HOME/.openclaw/workspace/config/openrouter_free_models.json"
TMPFILE=$(mktemp)
API="https://openrouter.ai/api/v1/models"

cleanup() { rm -f "$TMPFILE"; }
trap cleanup EXIT

# 1. 获取免费模型列表（prompt 和 completion 都为 "0"）
curl -fsSL --max-time 30 "$API" | jq '[.data[] | select(.pricing.prompt == "0" and .pricing.completion == "0") | {id, name, created, context_length, description}]' > "$TMPFILE" 2>/dev/null

if [ ! -s "$TMPFILE" ] || [ "$(cat "$TMPFILE" | jq 'length' 2>/dev/null)" == "0" ]; then
    echo "[ERROR] 获取 OpenRouter 免费模型列表失败" >&2
    exit 1
fi

CURRENT_COUNT=$(jq 'length' "$TMPFILE")

# 2. 首次运行：创建快照
if [ ! -f "$SNAPSHOT" ]; then
    cp "$TMPFILE" "$SNAPSHOT"
    echo "[INIT] 首次运行，已保存快照（${CURRENT_COUNT} 个免费模型）"
    exit 0
fi

# 3. 对比变化
NEW_MODELS=$(jq -n --argfile old "$SNAPSHOT" --argfile new "$TMPFILE" \
    '$new - $old | map({id, name, context_length, description: (.description // "" | .[0:120])})' 2>/dev/null)

REMOVED_MODELS=$(jq -n --argfile old "$SNAPSHOT" --argfile new "$TMPFILE" \
    '$old - $new | map({id, name})' 2>/dev/null)

NEW_COUNT=$(echo "$NEW_MODELS" | jq 'length' 2>/dev/null || echo 0)
REMOVED_COUNT=$(echo "$REMOVED_MODELS" | jq 'length' 2>/dev/null || echo 0)
OLD_COUNT=$(jq 'length' "$SNAPSHOT" 2>/dev/null || echo 0)
NEW_COUNT=${NEW_COUNT:-0}
REMOVED_COUNT=${REMOVED_COUNT:-0}
OLD_COUNT=${OLD_COUNT:-0}

# 4. 无变化则静默退出
if [ "$NEW_COUNT" == "0" ] && [ "$REMOVED_COUNT" == "0" ]; then
    echo "[OK] 无变化（当前 ${CURRENT_COUNT} 个免费模型）"
    exit 0
fi

# 5. 有变化：更新快照并输出报告
cp "$TMPFILE" "$SNAPSHOT"

echo "=== OpenRouter 免费模型变化 ==="
echo "时间: $(date '+%Y-%m-%d %H:%M')"
echo "旧数量: ${OLD_COUNT} → 新数量: ${CURRENT_COUNT}"

if [ "$NEW_COUNT" -gt 0 ]; then
    echo ""
    echo "🆕 新增 ${NEW_COUNT} 个免费模型:"
    echo "$NEW_MODELS" | jq -r '.[] | "  • \(.id)\n    \(.name)\n    上下文: \(.context_length) | \(.description // "")"'
fi

if [ "$REMOVED_COUNT" -gt 0 ]; then
    echo ""
    echo "❌ 下架 ${REMOVED_COUNT} 个模型:"
    echo "$REMOVED_MODELS" | jq -r '.[] | "  • \(.id) - \(.name)"'
fi

echo ""
echo "当前共 ${CURRENT_COUNT} 个免费模型"
