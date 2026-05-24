#!/usr/bin/env bash
# lobster-runner.sh v4 — lobster 语法执行器
set +u  # allow unbound vars

WF="${1:-}"
RESUME="${2:-}"
WORKSPACE="$HOME/.openclaw/workspace"
WF_NAME="$(basename "$WF" .lobster)"
STATE_DIR="$WORKSPACE/workflows/.lobster-state"
STATE_FILE="$STATE_DIR/$WF_NAME.state"

[[ -z "$WF" || ! -f "$WF" ]] && { echo "用法: lobster-runner.sh <workflow.lobster> [--resume]"; exit 1; }

echo "🦞 Lobster: $(grep '^# ' "$WF" | head -1 | sed 's/^# //')"
echo "───────────────────────────────────────────"
mkdir -p "$STATE_DIR"

get_out()  { local f="$STATE_FILE.out.$1"; [[ -f "$f" ]] && cat "$f"; }
set_out()  { echo "$3" > "$STATE_FILE.out.$1"; }
check_when() {
    local cond="$1"
    [[ "$cond" == "true" || -z "$cond" ]] && return 0
    if [[ "$cond" =~ ^\$([a-zA-Z0-9_]+)[\ ]*([><=!]+)[\ ]*([0-9]+) ]]; then
        actual=$(get_out "${BASH_REMATCH[1]}" | head -1)
        [[ -z "$actual" ]] && return 1
        val="${BASH_REMATCH[3]}"
        case "${BASH_REMATCH[2]}" in
            ">")  [[ "$actual" -gt "$val" ]]; return $? ;;
            "<")  [[ "$actual" -lt "$val" ]]; return $? ;;
            "=")  [[ "$actual" -eq "$val" ]]; return $? ;;
        esac
    fi
    return 0
}

# parse
declare -A S_run S_when S_approval S_stdin
in_step=""
while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^\[([a-zA-Z0-9_]+)\] ]] && { in_step="${BASH_REMATCH[1]}"; continue; }
    [[ -z "$in_step" ]] && continue
    [[ "$line" =~ ^(run|when|approval|stdin):[\ ]*(.*) ]] || continue
    case "${BASH_REMATCH[1]}" in
        run)      S_run["$in_step"]="${BASH_REMATCH[2]}" ;;
        when)     S_when["$in_step"]="${BASH_REMATCH[2]}" ;;
        approval) S_approval["$in_step"]="${BASH_REMATCH[2]}" ;;
        stdin)    S_stdin["$in_step"]="${BASH_REMATCH[2]}" ;;
    esac
done < "$WF"

# execute
for id in "${!S_run[@]}"; do
    [[ "$RESUME" == "--resume" && -f "$STATE_FILE.out.$id" ]] && { echo "⏭️  $id (resume跳过)"; continue; }
    when_cond="${S_when[$id]:-true}"
    check_when "$when_cond" || { echo "⏭️  $id (条件:$when_cond 不满足)"; continue; }

    cmd="${S_run[$id]}"
    stdin_src="${S_stdin[$id]:-}"
    approval="${S_approval[$id]:-}"

    echo -n "▶️  $id ... "
    if [[ -n "$stdin_src" && "$stdin_src" =~ ^\$([a-zA-Z0-9_]+) ]]; then
        src_id="${BASH_REMATCH[1]}"
        stdin_val="$(get_out "$src_id")"
        out=$(echo "$stdin_val" | eval "$cmd" 2>&1) || true
    else
        out=$(eval "$cmd" 2>&1) || true
    fi
    set_out "$id" "$out"
    echo "✅ $(echo "$out" | head -1 | cut -c1-60)"
    [[ -n "$approval" ]] && echo "   🔔 审批: $approval (自动批准)"
done

echo "───────────────────────────────────────────"
echo "✅ $WF_NAME 完成"
echo ""
echo "📊 结果:"
for id in "${!S_run[@]}"; do
    [[ -f "$STATE_FILE.out.$id" ]] && echo "  $id: $(get_out "$id" | head -1)"
done