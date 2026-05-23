#!/bin/bash
#===============================================
# OpenClaw 全能管理工具
# 用法：
#   bash openclaw-recovery.sh                → 交互式菜单
#   bash openclaw-recovery.sh backup         → 进入备份模式选择
#   bash openclaw-recovery.sh list           → 列出所有备份
#   bash openclaw-recovery.sh doctor|fix     → 一键故障排除
# 别名建议：
#   echo 'alias ocman="~/.openclaw/workspace/scripts/openclaw-recovery.sh"' >> ~/.bashrc
#===============================================
set -euo pipefail

# ── 颜色 ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; RESET='\033[0m'

# ── 路径 ──
OC_DIR="${OPENCLAW_DIR:-$HOME/.openclaw}"
CONFIG="$OC_DIR/openclaw.json"
BACKUP_DIR="${OC_DIR}/backups"
NOW=$(date +%Y-%m-%d_%H%M%S)
OC_BIN="$(command -v openclaw 2>/dev/null || echo '')"
BACKUP_FILES=()
SELECTED=""

# ── 小工具 ──
oc() { "$OC_BIN" "$@" 2>/dev/null || true; }
pause() { echo; echo -ne "  ${CYAN}按 Enter 继续...${RESET}"; read -r; }
ok()   { echo -e "  ${GREEN}✓${RESET} $*"; }
warn() { echo -e "  ${YELLOW}!${RESET} $*"; }
err()  { echo -e "  ${RED}✗${RESET} $*"; }
info() { echo -e "  ${CYAN}▶${RESET} $*"; }
sep()  { echo -e "  ${CYAN}────────────────────────────────────────────${RESET}"; }
section() { echo; echo -e "  ${BOLD}${MAGENTA}$1${RESET}"; sep; }

header() {
    clear 2>/dev/null || true
    echo -e "${CYAN}${BOLD}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║   OpenClaw 全能管理工具 🐉            ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${CYAN}$(date '+%Y-%m-%d %H:%M')${RESET}"
    local fsize="?"; [[ -f "$CONFIG" ]] && fsize=$(stat -c%s "$CONFIG" 2>/dev/null || echo "?")
    echo -e "  配置文件: ${CYAN}openclaw.json${RESET} (${fsize} bytes)"
    # 三层检测：CLI → 进程 → 端口
    local gw_stat; gw_stat=$(oc gateway status 2>/dev/null || true)
    local gw_listen; gw_listen=$(echo "$gw_stat" | grep -i 'Listening:' | grep -oP '\d+\.\d+\.\d+\.\d+:\d+' | tail -1)
    local gw_port; gw_port=$(echo "$gw_stat" | grep -oP 'port=\K\d+' | tail -1)

    if echo "$gw_stat" | grep -q 'Runtime: running'; then
        if [ -n "$gw_listen" ]; then
            echo -e "  Gateway:   ${GREEN}运行中${RESET}  (监听 $gw_listen)"
        else
            echo -e "  Gateway:   ${GREEN}运行中${RESET}"
        fi
    elif [ -n "$gw_listen" ]; then
        echo -e "  Gateway:   ${GREEN}运行中${RESET}  (端口 $gw_listen)"
    elif pgrep -f "openclaw.mjs gateway" &>/dev/null 2>/dev/null; then
        echo -e "  Gateway:   ${GREEN}运行中${RESET}  (进程)"
    elif ss -tlnp 2>/dev/null | grep -q "openclaw"; then
        local port; port=$(ss -tlnp 2>/dev/null | grep openclaw | grep -oP ':\K\d+' | head -1)
        echo -e "  Gateway:   ${GREEN}运行中${RESET}  (端口 $port)"
    elif [ -n "$gw_port" ] && ss -tlnp 2>/dev/null | grep -q ":$gw_port "; then
        echo -e "  Gateway:   ${GREEN}运行中${RESET}  (端口 $gw_port)"
    else
        echo -e "  Gateway:   ${RED}未运行${RESET}"
    fi
    sep
}

# ══════════════════════════════════════════
# 备份模式 A: 安全备份（停止 Gateway）
# ══════════════════════════════════════════
backup_mode_a() {
    info "准备安全备份..."
    local was_running=false

    if systemctl is-active openclaw-gateway.service &>/dev/null 2>/dev/null; then
        was_running=true
        warn "正在停止 Gateway..."
        oc gateway stop 2>/dev/null || true
        sleep 3
        if systemctl is-active openclaw-gateway.service &>/dev/null 2>/dev/null; then
            warn "Gateway 未完全停止，尝试 systemctl stop"
            sudo systemctl stop openclaw-gateway.service 2>/dev/null || true
            sleep 2
        fi
        ok "Gateway 已停止"
    fi

    echo
    info "执行安全备份..."
    local dest_dir="$BACKUP_DIR/safe-backup-$NOW"
    mkdir -p "$dest_dir"

    cp "$CONFIG" "$dest_dir/" 2>/dev/null && ok "openclaw.json" || warn "openclaw.json (无)"
    [[ -d "$OC_DIR/credentials" ]] && cp -r "$OC_DIR/credentials" "$dest_dir/" 2>/dev/null && ok "credentials/" || warn "credentials/ (无)"
    [[ -f "$OC_DIR/gateway-owner.json" ]] && cp "$OC_DIR/gateway-owner.json" "$dest_dir/" 2>/dev/null && ok "gateway-owner.json" || true

    # tar.gz 打包
    local archive="$BACKUP_DIR/openclaw-safe-${NOW}.tar.gz"
    if tar -czf "$archive" -C "$BACKUP_DIR" "safe-backup-$NOW" 2>/dev/null; then
        local asize; asize=$(stat -c%s "$archive" 2>/dev/null | numfmt --to=iec --format='%.1f' 2>/dev/null || stat -c%s "$archive" 2>/dev/null || echo "?")
        ok "打包完成: $(basename "$archive") (${asize}B)"
    else
        err "打包失败"
    fi

    # 兼容单文件备份
    cp "$CONFIG" "$BACKUP_DIR/openclaw.json.manual-backup-$NOW" 2>/dev/null || true

    # 恢复 Gateway
    if $was_running; then
        echo
        info "正在恢复 Gateway 运行..."
        oc gateway start 2>/dev/null || true
        sleep 2
        systemctl is-active openclaw-gateway.service &>/dev/null 2>/dev/null \
            && ok "Gateway 已恢复运行" \
            || warn "Gateway 未自动恢复，请手动: openclaw gateway start"
    fi

    echo
    ok "安全备份完成！"
    echo -e "  打包文件: ${CYAN}${archive}${RESET}"
    echo -e "  原始目录: ${CYAN}${dest_dir}/${RESET}"
    return 0
}

# ══════════════════════════════════════════
# 备份模式 B: 热备份（不停止 Gateway）
# ══════════════════════════════════════════
backup_mode_b() {
    info "Gateway 保持运行，执行热备份..."

    local dest_dir="$BACKUP_DIR/hot-backup-$NOW"
    mkdir -p "$dest_dir"

    cp "$CONFIG" "$dest_dir/" 2>/dev/null && ok "openclaw.json" || warn "openclaw.json (无)"
    [[ -d "$OC_DIR/credentials" ]] && cp -r "$OC_DIR/credentials" "$dest_dir/" 2>/dev/null && ok "credentials/" || warn "credentials/ (无)"

    cp "$CONFIG" "$BACKUP_DIR/openclaw.json.manual-backup-$NOW" 2>/dev/null || true

    echo
    ok "热备份完成！"
    echo -e "  备份路径: ${CYAN}${dest_dir}/${RESET}"
    echo -e "  ${YELLOW}(如需完整一致的安全备份，下次请选 A)${RESET}"
    return 0
}

# ══════════════════════════════════════════
# 备份模式 C: 仅备份配置文件（推荐日常）
# ══════════════════════════════════════════
backup_mode_c() {
    info "Gateway 不中断，仅备份关键配置文件..."

    local dest="$BACKUP_DIR/openclaw.json.manual-backup-$NOW"
    if cp "$CONFIG" "$dest"; then
        chmod 600 "$dest"
        local dsize; dsize=$(stat -c%s "$dest" 2>/dev/null | numfmt --to=iec --format='%.1f' 2>/dev/null || stat -c%s "$dest" 2>/dev/null || echo "?")
        ok "openclaw.json → $(basename "$dest") (${dsize}B)"
    else
        err "openclaw.json 备份失败！"
    fi

    if [[ -d "$OC_DIR/credentials" ]]; then
        local cred_dest="$BACKUP_DIR/credentials-backup-$NOW"
        cp -r "$OC_DIR/credentials" "$cred_dest" 2>/dev/null \
            && ok "credentials/ → $(basename "$cred_dest")" \
            || warn "credentials/ 备份失败"
    fi

    echo
    ok "日常备份完成，Gateway 运行正常"
    return 0
}

# ══════════════════════════════════════════
# [1] 备份菜单（A/B/C 三模式）
# ══════════════════════════════════════════
backup_menu() {
    header
    echo -e "  ${BOLD}备份模式选择：${RESET}"
    echo
    echo -e "  ${YELLOW}A)${RESET} 安全备份（停止 Gateway）— 推荐"
    echo -e "     先停止 Gateway，确保配置静止"
    echo -e "     完整一致，约 5-10 秒停机"
    echo -e "     备份内容：openclaw.json + credentials/ → tar.gz"
    echo
    echo -e "  ${YELLOW}B)${RESET} 热备份（不停止 Gateway）"
    echo -e "     Gateway 保持运行，配置实时备份"
    echo -e "     备份期间配置可能被修改，可能不完全一致"
    echo -e "     备份内容：openclaw.json + credentials/ (目录)"
    echo
    echo -e "  ${YELLOW}C)${RESET} 仅备份配置文件（推荐日常）"
    echo -e "     ${GREEN}2 步搞定：cp openclaw.json + chmod 600"
    echo -e "     快速、无停机、占用小、Gateway 不中断"
    echo -e "     备份内容：仅 openclaw.json + credentials/"
    echo
    echo -e "  ${YELLOW}0)${RESET} 返回主菜单"
    echo
    echo -ne "  ${BOLD}请选择 [A/B/C/0]: ${RESET}"
    read -r mode
    mode="${mode^^}"
    [[ "$mode" == "0" ]] && return
    case "$mode" in
        A) backup_mode_a ;;
        B) backup_mode_b ;;
        C) backup_mode_c ;;
        *) echo -e "  ${RED}无效选择${RESET}"; sleep 1 ;;
    esac
}

# ══════════════════════════════════════════
# [2] 备份列表（含 JSON 有效性验证）
# ══════════════════════════════════════════
list_backups() {
    header
    echo -e "  ${BOLD}备份列表${RESET}"
    echo

    # 收集所有 .manual-backup-* 文件 + tar.gz + json
    local tmpfile; tmpfile=$(mktemp /tmp/oc_backups.XXXXXX)
    find "$BACKUP_DIR" -maxdepth 1 \( -name 'openclaw.json.manual-backup-*' -o -name 'openclaw-*.tar.gz' -o -name 'openclaw-safe-*.tar.gz' \) \
        -printf '%T@\t%p\n' 2>/dev/null | sort -rn -t$'\t' -k1 > "$tmpfile"

    if [[ ! -s "$tmpfile" ]]; then
        echo -e "  ${YELLOW}未找到任何备份文件！${RESET}"
        echo -e "  备份目录：${CYAN}${BACKUP_DIR}/${RESET}"
        rm -f "$tmpfile"
        return 1
    fi

    printf "  ${CYAN}%-4s %-22s %-10s %-6s %s${RESET}\n" "序号" "备份时间" "大小" "有效" "文件名"
    echo -e "  ───────────────────────────────────────────────────────"

    local i=0; BACKUP_FILES=()
    while IFS=$'\t' read -r _ f; do
        [ -z "$f" ] && continue
        ((i++))
        local name; name=$(basename "$f")
        local size; size=$(stat -c%s "$f" 2>/dev/null || echo "0")
        local size_hr; size_hr=$(numfmt --to=iec --format='%.1f' "$size" 2>/dev/null || echo "${size}B")
        local mtime; mtime=$(stat -c '%y' "$f" 2>/dev/null | cut -d. -f1)
        local valid="?"
        if [[ "$f" == *.json.* ]]; then
            python3 -c "import json; json.load(open('$f'))" 2>/dev/null && valid="OK" || valid="✗"
        elif [[ "$f" == *.tar.gz ]]; then
            valid="tar"
        fi
        printf "  ${YELLOW}%3d)${RESET} %-22s %-10s %-6s %s\n" "$i" "$mtime" "$size_hr" "$valid" "$name"
        BACKUP_FILES+=("$f")
    done < "$tmpfile"
    rm -f "$tmpfile"

    echo
    ok "共 ${#BACKUP_FILES[@]} 个备份文件"
    echo -e "  目录：${CYAN}${BACKUP_DIR}/${RESET}"
    return 0
}

# ══════════════════════════════════════════
# [3] 选择备份并恢复
# ══════════════════════════════════════════
select_backup() {
    [[ ${#BACKUP_FILES[@]} -eq 0 ]] && { err "没有可选的备份文件"; return 1; }
    while true; do
        echo
        read -rp "  请输入要恢复的备份序号 (0=返回): " choice
        choice="${choice// /}"
        [[ "$choice" == "0" ]] && { echo; info "返回"; return 1; }
        ! [[ "$choice" =~ ^[0-9]+$ ]] && { warn "请输入有效数字"; continue; }
        local idx=$((choice - 1))
        if [[ $idx -ge 0 && $idx -lt ${#BACKUP_FILES[@]} ]]; then
            SELECTED="${BACKUP_FILES[$idx]}"
            ok "已选择: $(basename "$SELECTED")"
            return 0
        else
            warn "序号超出范围 (1-${#BACKUP_FILES[@]})"
        fi
    done
}

do_restore() {
    local src="$1"
    header
    echo -e "  ${BOLD}恢复确认${RESET}"
    echo
    echo -e "  文件：${CYAN}$(basename "$src")${RESET}"
    local fsize; fsize=$(stat -c%s "$src" 2>/dev/null || echo "?")
    local fdate; fdate=$(stat -c '%y' "$src" 2>/dev/null | cut -d. -f1)
    echo -e "  大小：${fsize} bytes"
    echo -e "  时间：${fdate}"
    echo
    read -rp "  确定恢复此备份？[y/N]: " confirm
    case "$confirm" in [yY]|[yY][eE][sS]) ;; *) info "已取消"; return 1 ;; esac

    # 先自动备份当前（C 模式最轻量）
    echo
    info "恢复前自动备份当前配置..."
    NOW=$(date +%Y-%m-%d_%H%M%S)
    cp "$CONFIG" "$BACKUP_DIR/openclaw.json.manual-backup-$NOW" 2>/dev/null \
        && ok "当前配置已备份至: openclaw.json.manual-backup-$NOW" \
        || warn "备份当前配置失败（但不会阻止恢复）"

    # 执行恢复
    echo
    info "正在恢复..."
    if [[ "$src" == *.tar.gz ]]; then
        # tar.gz 完整恢复
        warn "检测到 tar.gz 完整备份"
        read -rp "  此操作将覆盖 ~/.openclaw 目录，确认？[y/N]: " c2
        [[ "${c2^^}" != "Y" ]] && { info "已取消"; return 1; }
        info "停止 Gateway ..."
        oc gateway stop 2>/dev/null || true; sleep 1
        [ -d "$HOME/.openclaw-old" ] && rm -rf "$HOME/.openclaw-old"
        mv "$OC_DIR" "$HOME/.openclaw-old" 2>/dev/null || true
        mkdir -p "$OC_DIR"
        if tar -xzf "$src" -C "$HOME" 2>/dev/null; then
            ok "tar.gz 完整备份已恢复"
        else
            err "解压失败，回滚"
            rm -rf "$OC_DIR"; mv "$HOME/.openclaw-old" "$OC_DIR"
            return 1
        fi
        echo -e "  旧配置保留在 ${CYAN}~/.openclaw-old${RESET}，确认后可删除"
    else
        # JSON 单文件恢复
        if cp "$src" "$CONFIG"; then
            chmod 600 "$CONFIG"
            ok "配置恢复成功！"
        else
            err "配置恢复失败！"
            return 1
        fi
    fi
    return 0
}

validate_config() {
    [[ ! -f "$CONFIG" ]] && { err "配置文件不存在！"; return 1; }
    echo
    sep
    echo -e "  ${BOLD}配置验证${RESET}"
    if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
        ok "JSON 格式验证通过"
        python3 -c "
import json
c=json.load(open('$CONFIG'))
print(f'  agents 段: OK' if 'agents' in c else '  agents 段: WARNING 缺失')
print(f'  配置大小: {len(json.dumps(c))} 字节')
m=c.get('models',{}).get('providers',{})
print(f'  模型厂商: {len(m)} 个' if m else '  模型厂商: 未配置')
" 2>/dev/null || true
        return 0
    else
        err "JSON 无效！请确认备份文件未被损坏"
        return 1
    fi
}

# ══════════════════════════════════════════
# [4] 重启 Gateway
# ══════════════════════════════════════════
restart_gateway() {
    header
    echo -e "  ${BOLD}[4] 重启 Gateway${RESET}\n"
    echo -e "  1) 重启 Gateway"
    echo -e "  0) 稍后手动重启"
    echo
    read -rp "  请选择 [1/0]: " rchoice
    case "${rchoice// /}" in
        1)
            info "正在重启 Gateway..."
            if oc gateway restart 2>/dev/null; then
                sleep 2
                ok "Gateway 重启成功"
                systemctl is-active openclaw-gateway.service &>/dev/null 2>/dev/null \
                    && ok "Gateway 运行中" \
                    || warn "请检查: openclaw gateway status"
            else
                warn "自动重启失败，请手动: openclaw gateway restart"
            fi
            ;;
        *) info "稍后手动重启: openclaw gateway restart" ;;
    esac
}

# ══════════════════════════════════════════
# [5] 查看配置摘要
# ══════════════════════════════════════════
show_summary() {
    header
    echo -e "  ${BOLD}[5] 配置摘要${RESET}\n"

    [[ ! -f "$CONFIG" ]] && { warn "配置文件不存在"; return; }

    echo -e "  ${CYAN}── 模型配置 ──${RESET}"
    python3 -c "
import json
c=json.load(open('$CONFIG'))
# 主模型来自 agents.defaults.model.primary
agents=c.get('agents',{}).get('defaults',{})
print(f'  代理主模型: {agents.get(\"model\",{}).get(\"primary\",\"未设置\")}')
fb=agents.get('model',{}).get('fallbacks',[])
if fb: print(f'  备用模型: {\", \".join(fb[:3])}')
# 模型厂商来自 models.providers（复数）
providers=c.get('models',{}).get('providers',{})
print(f'  模型厂商: {len(providers)} 个')
for k,v in providers.items():
    raw=(v.get('models') or v.get('supportedModels') or [])[:3]
    names=[]
    for m in raw:
        if isinstance(m,str): names.append(m)
        elif isinstance(m,dict): names.append(m.get('id',m.get('name','?')))
    print(f'    {k}: {\", \".join(names) if names else \"(无)\"}')
ch=c.get('channels',{})
if ch:
    names=[n.get('name','?') for n in ch.values() if isinstance(n,dict)]
    print(f'  通道: {\", \".join(names) if names else \"无\"}')
print(f'  配置大小: {len(json.dumps(c))} 字节')
" 2>/dev/null || echo -e "  ${YELLOW}无法解析${RESET}"

    echo
    echo -e "  ${CYAN}── 系统信息 ──${RESET}"
    echo -e "  openclaw: $($OC_BIN --version 2>/dev/null || echo '?')"
    echo -e "  node:     $(node -v 2>/dev/null || echo '?')"
    echo -e "  ~/.openclaw: $(du -sh "$OC_DIR" 2>/dev/null | cut -f1)"

    echo
    echo -e "  ${CYAN}── 关键文件 ──${RESET}"
    for it in openclaw.json credentials agents workspace/SOUL.md; do
        [ -e "$OC_DIR/$it" ] && echo -e "  ${GREEN}✓${RESET} $it" || echo -e "  ${RED}✗${RESET} $it (缺失)"
    done

    # 备份统计
    local bcnt; bcnt=$(find "$BACKUP_DIR" -maxdepth 1 \( -name 'openclaw.json.manual-backup-*' -o -name 'openclaw-*.tar.gz' -o -name 'openclaw-safe-*.tar.gz' \) 2>/dev/null | wc -l)
    echo -e "  备份数量: ${bcnt}"
}

# ══════════════════════════════════════════
# [6] 🔧 故障排除（一键诊断+修复）
# ══════════════════════════════════════════
troubleshoot() {
    header
    echo -e "  ${BOLD}${MAGENTA}[6] 🔧 故障排除（一键诊断+修复）${RESET}\n"
    echo -e "  基于 docs.openclaw.ai/gateway/troubleshooting"
    echo -e "  流程：诊断 5 阶段 → 汇总 → 确认 → 自动修复\n"
    read -rp "  按 Enter 开始诊断，b 返回: " c
    [[ "${c^^}" == "B" ]] && return

    header
    echo -e "  ${BOLD}${MAGENTA}🔍 开始诊断...${RESET}\n"
    local ALL_OK=true; local FIX_NEEDED=""
    local ISSUES_FILE; ISSUES_FILE=$(mktemp /tmp/oc-troubleshoot-XXXXXX)

    # Phase 1: Command Ladder
    section "Phase 1/5: 基础诊断 (Command Ladder)"
    info "openclaw status"
    oc status 2>/dev/null | head -8 || echo "  (无输出)"
    info "openclaw gateway status"
    local gw_out; gw_out=$(oc gateway status 2>/dev/null || true)
    echo "$gw_out" | head -5
    if echo "$gw_out" | grep -q 'Runtime: running'; then ok "Gateway 运行中"
    else warn "Gateway 可能未运行"; FIX_NEEDED="${FIX_NEEDED} gw_down"; ALL_OK=false; fi
    echo "$gw_out" | grep -q 'Connectivity probe: ok' && ok "连通性正常" || { warn "连通性异常"; FIX_NEEDED="${FIX_NEEDED} conn"; }

    # Phase 2: Doctor
    section "Phase 2/5: 深度诊断 (Doctor)"
    info "openclaw doctor"
    local doc_out; doc_out=$(oc doctor 2>/dev/null || true)
    echo "$doc_out" | head -15
    echo "$doc_out" | grep -qi 'dependency.*corrupt' && { err "依赖树损坏"; echo "dep" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} dep"; ALL_OK=false; }
    echo "$doc_out" | grep -qi 'stale.*oauth\|stale.*auth' && { err "过期认证"; echo "auth" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} auth"; ALL_OK=false; }
    echo "$doc_out" | grep -qi 'EADDRINUSE\|port conflict' && { err "端口冲突"; echo "port" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} port"; ALL_OK=false; }
    echo "$doc_out" | grep -qi 'other gateway-like' && { warn "重复 Gateway 服务"; echo "dup" >> "$ISSUES_FILE"; }

    # Phase 3: 版本检查
    section "Phase 3/5: 版本检查"
    local ver; ver=$($OC_BIN --version 2>/dev/null || echo '?')
    echo -e "  openclaw: ${CYAN}${ver}${RESET}"
    local ltv; ltv=$(oc config get meta.lastTouchedVersion 2>/dev/null || echo '')
    [ -n "$ltv" ] && [ "$ltv" != "null" ] && echo -e "  lastTouchedVersion: ${CYAN}${ltv}${RESET}"
    local count_oc; count_oc=$(which -a openclaw 2>/dev/null | wc -l)
    [ "$count_oc" -gt 1 ] && { warn "PATH 中有 ${count_oc} 个 openclaw"; echo "split" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} split"; ALL_OK=false; }

    # Phase 4: 日志扫描
    section "Phase 4/5: 日志异常扫描"
    info "扫描最近 100 行..."
    local log_errs; log_errs=$(oc logs 2>/dev/null | tail -100 | grep -iE 'error|fail|panic|401|429|404|protocol mismatch|symlink-escape|memory pressure|incomplete turn' | tail -15 || true)
    if [ -n "$log_errs" ]; then
        warn "发现异常:"
        echo -e "${YELLOW}$log_errs${RESET}"
        echo "$log_errs" | grep -qi 'protocol mismatch' && { echo "proto" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} proto"; }
        echo "$log_errs" | grep -qi '401\|429' && { echo "auth_http" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} auth_http"; }
        echo "$log_errs" | grep -qi 'memory pressure' && { echo "mem" >> "$ISSUES_FILE"; FIX_NEEDED="${FIX_NEEDED} mem"; }
    else ok "日志无明显异常"; fi

    # Phase 5: 修复
    section "Phase 5/5: 自动修复"
    if [ "$ALL_OK" = true ]; then
        ok "🎉 系统状态良好，无需修复！"
        echo -e "  ✅ Gateway 运行正常  ✅ Doctor 无阻塞  ✅ 版本一致  ✅ 日志无异常"
        rm -f "$ISSUES_FILE"; pause; return
    fi

    echo -e "  ${YELLOW}${BOLD}检测到问题：${RESET}"
    cat "$ISSUES_FILE" 2>/dev/null
    echo; read -rp "  是否执行自动修复？[y/N]: " c
    [[ "${c^^}" != "Y" ]] && { echo -e "\n  ${YELLOW}跳过修复${RESET}"; rm -f "$ISSUES_FILE"; pause; return; }

    echo; local FC=0
    [[ "$FIX_NEEDED" == *dep* ]] || [[ "$FIX_NEEDED" == *auth* ]] && { info "openclaw doctor --fix"; oc doctor --fix 2>/dev/null; ok "已执行"; ((FC++)); }
    [[ "$FIX_NEEDED" == *gw_down* ]] || [[ "$FIX_NEEDED" == *conn* ]] || [[ "$FIX_NEEDED" == *port* ]] && {
        info "重启 Gateway..."; oc gateway stop 2>/dev/null || true; sleep 1
        if oc gateway start 2>/dev/null; then sleep 3; ok "Gateway 已重启"; ((FC++));
        else
            local mode; mode=$(oc config get gateway.mode 2>/dev/null || echo '')
            [ -z "$mode" ] || [ "$mode" = "null" ] && { warn "gateway.mode 缺失，设为 local"; oc config set gateway.mode local 2>/dev/null || true; sleep 1; oc gateway start 2>/dev/null && ok "已修复" || err "启动失败"; }
        fi
    }
    [[ "$FIX_NEEDED" == *proto* ]] && {
        info "清理残留客户端..."; oc gateway status --deep 2>/dev/null | grep -oP 'pid=\K\d+' | while read p; do kill "$p" 2>/dev/null && echo "  终止 PID $p"; done; ok "已清理"; ((FC++));
    }
    [[ "$FIX_NEEDED" == *auth_http* ]] && { info "认证/限流 → 检查 API Key 或套餐额度"; ((FC++)); }
    [[ "$FIX_NEEDED" == *split* ]] && { info "多版本 → 确保 PATH 使用最新 openclaw"; ((FC++)); }

    echo; sep
    ok "修复完成，共执行 ${FC} 项"
    echo -e "  建议验证: ${CYAN}openclaw status && openclaw gateway status${RESET}"
    rm -f "$ISSUES_FILE"
}

# ══════════════════════════════════════════
# [7] 快速修复
# ══════════════════════════════════════════
quick_fix() {
    header
    echo -e "  ${BOLD}[7] 快速修复 (doctor --fix)${RESET}\n"
    oc doctor --fix 2>&1 || warn "openclaw 命令不可用"
    echo
    read -rp "  修复完成，是否重启 Gateway？[y/N]: " fr
    case "${fr,,}" in y|yes) oc gateway restart 2>/dev/null || true; ok "已重启" ;; esac
}

# ══════════════════════════════════════════
# [8] 模型管理（查看/切换/增删）
# ══════════════════════════════════════════
model_manager() {
    while true; do
        header
        echo -e "  ${BOLD}${MAGENTA}[8] 🧠 模型管理${RESET}\n"

        # 读取当前配置
        local primary fb provider_list
        primary=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
print(c.get('agents',{}).get('defaults',{}).get('model',{}).get('primary','未设置'))
" 2>/dev/null)
        fb=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
fb_list=c.get('agents',{}).get('defaults',{}).get('model',{}).get('fallbacks',[])
print(', '.join(fb_list) if fb_list else '无')
" 2>/dev/null)
        provider_list=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
for p in c.get('models',{}).get('providers',{}).keys():
    print(p)
" 2>/dev/null)

        # 显示模型状态
        echo -e "  ${CYAN}── 当前模型配置 ──${RESET}"
        echo -e "  主模型:   ${GREEN}${primary}${RESET}"
        echo -e "  备用模型: ${YELLOW}${fb}${RESET}"
        echo
        echo -e "  ${CYAN}── 模型厂商 (Provider) ──${RESET}"
        local i=0
        while IFS= read -r p; do
            local count=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
models=c.get('models',{}).get('providers',{}).get('$p',{}).get('models',[])
print(len(models))
" 2>/dev/null)
            echo -e "  ${YELLOW}$((i+1)))${RESET} ${p} (${count} 个模型)"
            ((i++))
        done <<< "$provider_list"
        echo

        echo -e "  ${BOLD}操作菜单：${RESET}"
        echo -e "  ${YELLOW}A)${RESET} 切换主模型"
        echo -e "  ${YELLOW}B)${RESET} 修改备用模型列表"
        echo -e "  ${YELLOW}C)${RESET} 查看某个 Provider 的全部模型"
        echo -e "  ${YELLOW}D)${RESET} 运行模型自动检测注册 (model-discovery)"
        echo -e "  ${YELLOW}R)${RESET} 模型排名对比（按能力/价格）"
        echo -e "  ${YELLOW}0)${RESET} 返回主菜单"
        echo
        echo -ne "  ${BOLD}请选择 [A/B/C/D/R/0]: ${RESET}"
        read -r choice
        choice="${choice^^}"

        case "$choice" in
            A) model_switch_primary ;;
            B) model_edit_fallbacks ;;
            C) model_browse_provider ;;
            D) run_model_discovery ;;
            R) model_ranking ;;
            0) return ;;
            *) echo -e "  ${RED}无效选择${RESET}"; sleep 1 ;;
        esac
    done
}

model_switch_primary() {
    header
    echo -e "  ${BOLD}切换主模型${RESET}\n"
    echo -e "  ${CYAN}当前主模型: ${GREEN}$(python3 -c "import json;c=json.load(open('$CONFIG'));print(c.get('agents',{}).get('defaults',{}).get('model',{}).get('primary','?'))" 2>/dev/null)${RESET}\n"

    # 列出所有可用模型（简化选择）
    echo -e "  ${CYAN}常用模型：${RESET}"
    python3 -c "
import json
c=json.load(open('$CONFIG'))
providers=c.get('models',{}).get('providers',{})
idx=0
for pname,pdata in providers.items():
    for m in pdata.get('models',[]):
        mid=m if isinstance(m,str) else m.get('id','?')
        mname=m if isinstance(m,str) else m.get('name',mid)
        reasoning='🧠' if (isinstance(m,dict) and m.get('reasoning')) else ''
        idx+=1
        print(f'  {idx:3d}) {reasoning} {pname}/{mid}')
        if idx>=20: break
    if idx>=20: break
" 2>/dev/null
    echo -e "  ${YELLOW}  (仅显示前20个，更多请用 model/{full_id} 直接输入)${RESET}"
    echo
    echo -e "  ${CYAN}输入格式示例：${RESET} nvidia/minimaxai/minimax-m2.7"
    echo -e "  ${CYAN}或者输入序号：${RESET} 1"
    echo -ne "  ${BOLD}请输入新主模型 (0=返回): ${RESET}"
    read -r new_model
    [[ "$new_model" == "0" ]] && return

    # 判断是序号还是完整 ID
    if [[ "$new_model" =~ ^[0-9]+$ ]]; then
        new_model=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
idx=int('$new_model')-1
count=0
for pname,pdata in c.get('models',{}).get('providers',{}).items():
    for m in pdata.get('models',[]):
        if count==idx:
            print(f'{pname}/{m}' if isinstance(m,str) else f'{pname}/{m.get(\"id\",\"?\")}')
            exit()
        count+=1
" 2>/dev/null)
    fi

    if [ -z "$new_model" ]; then
        err "无效模型 ID"
        pause; return
    fi

    # 切换
    echo
    info "切换主模型到: $new_model"
    if oc config set agents.defaults.model.primary "$new_model" 2>/dev/null; then
        ok "主模型已切换为: ${GREEN}${new_model}${RESET}"
        info "Gateway 在线热加载，无需重启"
    else
        err "切换失败，请检查模型 ID 是否正确"
    fi
    pause
}

model_edit_fallbacks() {
    header
    echo -e "  ${BOLD}修改备用模型列表${RESET}\n"
    echo -e "  ${CYAN}当前备用模型：${RESET}"
    python3 -c "
import json
c=json.load(open('$CONFIG'))
fb=c.get('agents',{}).get('defaults',{}).get('model',{}).get('fallbacks',[])
for i,m in enumerate(fb): print(f'  {i+1}. {m}')
if not fb: print('  (无)')
" 2>/dev/null
    echo
    echo -e "  ${CYAN}输入格式：${RESET} provider/model_id, 多个用逗号分隔"
    echo -e "  ${CYAN}示例：${RESET} deepseek/deepseek-v4-pro, nvidia/qwen/qwen3-next-80b-a3b-instruct"
    echo -ne "  ${BOLD}请输入新备用模型列表 (0=返回): ${RESET}"
    read -r new_fb
    [[ "$new_fb" == "0" ]] && return

    if oc config set agents.defaults.model.fallbacks "$new_fb" 2>/dev/null; then
        ok "备用模型已更新"
    else
        err "更新失败"
    fi
    pause
}

model_browse_provider() {
    header
    echo -e "  ${BOLD}查看 Provider 全部模型${RESET}\n"

    # 列出 provider
    python3 -c "
import json
c=json.load(open('$CONFIG'))
for i,(p,_) in enumerate(c.get('models',{}).get('providers',{}).items()):
    print(f'{i+1}) {p}')
" 2>/dev/null
    echo
    echo -ne "  ${BOLD}选择 Provider 序号 (0=返回): ${RESET}"
    read -r pidx
    [[ "$pidx" == "0" ]] && return

    local pname=$(python3 -c "
import json
c=json.load(open('$CONFIG'))
providers=list(c.get('models',{}).get('providers',{}).keys())
print(providers[int('$pidx')-1] if 0<int('$pidx')<=len(providers) else '')
" 2>/dev/null)

    if [ -z "$pname" ]; then
        err "无效序号"; pause; return
    fi

    header
    echo -e "  ${BOLD}${pname} — 全部模型${RESET}\n"
    python3 -c "
import json
c=json.load(open('$CONFIG'))
models=c.get('models',{}).get('providers',{}).get('$pname',{}).get('models',[])
print(f'  {"序号":<5} {"模型 ID":<55} {"上下文":<10} {"maxTokens":<10} {"推理":<6}')
print(f'  {"─"*5} {"─"*55} {"─"*10} {"─"*10} {"─"*6}')
for i,m in enumerate(models):
    mid=m if isinstance(m,str) else m.get('id','?')
    cw=m.get('contextWindow','?') if isinstance(m,dict) else '?'
    mt=m.get('maxTokens','?') if isinstance(m,dict) else '?'
    r='🧠' if (isinstance(m,dict) and m.get('reasoning')) else ''
    # 格式化数字
    try:
        cw_str=f'{int(cw)//1000}k' if isinstance(cw,int) or (isinstance(cw,str) and cw.isdigit()) else str(cw)[:8]
    except: cw_str=str(cw)[:8]
    try:
        mt_str=f'{int(mt)//1000}k' if isinstance(mt,int) or (isinstance(mt,str) and mt.isdigit()) else str(mt)[:8]
    except: mt_str=str(mt)[:8]
    print(f'  {i+1:<5} {mid[:52]:<55} {cw_str:<10} {mt_str:<10} {r:<6}')
print(f'\n  共 {len(models)} 个模型')
" 2>/dev/null
    pause
}

run_model_discovery() {
    header
    echo -e "  ${BOLD}运行模型自动检测注册${RESET}\n"
    local disc_script="$HOME/maintenance/scripts/model-discovery.sh"
    if [ -f "$disc_script" ]; then
        info "执行 model-discovery.sh list ..."
        echo
        bash "$disc_script" list 2>/dev/null || warn "执行失败"
        echo
        read -rp "  是否执行完整检测并注册新模型？[y/N]: " c
        [[ "${c^^}" == "Y" ]] && {
            info "正在检测..."
            bash "$disc_script" full 2>/dev/null && ok "检测完成" || warn "检测失败"
        }
    else
        err "找不到 model-discovery.sh"
    fi
    pause
}

model_ranking() {
    header
    echo -e "  ${BOLD}模型排名对比${RESET}\n"
    echo -e "  ${CYAN}按综合能力排序 (3 个 Provider 中的模型)${RESET}\n"
    python3 -c "
import json
c=json.load(open('$CONFIG'))
providers=c.get('models',{}).get('providers',{})
entries=[]
for pname,pdata in providers.items():
    for m in pdata.get('models',[]):
        if not isinstance(m,dict): continue
        mid=m.get('id','?')
        cw=m.get('contextWindow',0) or 0
        mt=m.get('maxTokens',0) or 0
        cost=m.get('cost',{}) or {}
        total_cost=cost.get('input',0)+cost.get('output',0)
        reasoning=2 if m.get('reasoning') else 0
        vision=1 if 'image' in m.get('input',[]) else 0
        # 综合分 = 上下文 + Token数归一化 + 推理 + 视觉 - 价格
        score=(cw/100000)*5 + (mt/100000)*2 + reasoning*3 + vision*2 - total_cost*2
        entries.append((-score, total_cost, cw, mt, reasoning>0, vision>0, pname, mid))
entries.sort()
print(f'  {"排名":<5} {"模型":<52} {"上下文":<8} {"推理":<5} {"视觉":<5} {"约价格":<8}')
print(f'  {"─"*5} {"─"*52} {"─"*8} {"─"*5} {"─"*5} {"─"*8}')
for rank,(neg_s, cost, cw, mt, rs, vis, pname, mid) in enumerate(entries[:15]):
    try: cw_s=f'{int(cw)//1000}k'
    except: cw_s='?'
    cost_s='' if cost==0 else f'\${cost:.1f}'
    print(f'  {rank+1:<5} {pname}/{mid[:45]:<50} {cw_s:<8} {\"🧠\" if rs else \"  \":<5} {\"👁️\" if vis else \"  \":<5} {cost_s:<8}')
if len(entries)>15: print(f'  ... 另有 {len(entries)-15} 个模型')
" 2>/dev/null
    pause
}

# ══════════════════════════════════════════
# [9] 模型测试（连通性+响应）
# ══════════════════════════════════════════
model_tester() {
    while true; do
        header
        echo -e "  ${BOLD}${MAGENTA}[9] 🔬 模型测试${RESET}\n"
        echo -e "  ${YELLOW}1)${RESET} 测试所有 Provider 连通性"
        echo -e "  ${YELLOW}2)${RESET} 测试指定模型响应（发一条消息看返回）"
        echo -e "  ${YELLOW}3)${RESET} 测试当前主模型延迟"
        echo -e "  ${YELLOW}4)${RESET} 批量测试备用模型速度"
        echo -e "  ${YELLOW}0)${RESET} 返回主菜单"
        echo
        echo -ne "  ${BOLD}请选择 [1-4/0]: ${RESET}"
        read -r choice

        case "$choice" in
            1) test_provider_connectivity ;;
            2) test_single_model ;;
            3) test_primary_latency ;;
            4) test_fallback_batch ;;
            0) return ;;
            *) echo -e "  ${RED}无效选择${RESET}"; sleep 1 ;;
        esac
    done
}

test_provider_connectivity() {
    header
    echo -e "  ${BOLD}测试 Provider 连通性${RESET}\n"
    python3 -c "
import json, urllib.request, ssl, time
c=json.load(open('$CONFIG'))
providers=c.get('models',{}).get('providers',{})
ctx=ssl.create_default_context()

for pname,pdata in providers.items():
    base=pdata.get('baseUrl','')
    apikey=pdata.get('apiKey','')
    if not base:
        print(f'  ⚠️  {pname}: 无 baseUrl，跳过')
        continue
    # 测试 /models 端点
    url=base.rstrip('/')+'/models'
    try:
        req=urllib.request.Request(url)
        req.add_header('Authorization',f'Bearer {apikey}')
        t0=time.time()
        resp=urllib.request.urlopen(req, timeout=10, context=ctx)
        t=time.time()-t0
        data=json.loads(resp.read().decode())
        if 'data' in data:
            print(f'  ✅ {pname}: {(t*1000):.0f}ms, {len(data[\"data\"])} 模型可用')
        elif isinstance(data,list):
            print(f'  ✅ {pname}: {(t*1000):.0f}ms, {len(data)} 条目')
        else:
            print(f'  ✅ {pname}: {(t*1000):.0f}ms, 响应正常')
    except Exception as e:
        err=str(e)[:60]
        if '401' in err or '403' in err:
            print(f'  ❌ {pname}: 认证失败 (API Key 无效或过期)')
        elif 'timeout' in err.lower():
            print(f'  ❌ {pname}: 超时 (网络不通)')
        else:
            print(f'  ❌ {pname}: {err}')
" 2>/dev/null
    pause
}

test_single_model() {
    header
    echo -e "  ${BOLD}测试指定模型响应${RESET}\n"
    echo -ne "  ${BOLD}输入模型 ID (如 deepseek/deepseek-v4-flash, 0=返回): ${RESET}"
    read -r model_id
    [[ "$model_id" == "0" ]] && return

    local provider="${model_id%%/*}"
    local model_name="${model_id#*/}"

    echo
    info "测试 ${provider}/${model_name} ..."
    python3 -c "
import json, urllib.request, ssl, time
c=json.load(open('$CONFIG'))
pdata=c.get('models',{}).get('providers',{}).get('$provider',{})
base=pdata.get('baseUrl','')
apikey=pdata.get('apiKey','')
if not base:
    print('❌ Provider 不存在或无 baseUrl')
    exit()
url=base.rstrip('/')+'/chat/completions'
data=json.dumps({
    'model':'$model_name',
    'messages':[{'role':'user','content':'Hi. Reply with just "OK" and nothing else.'}],
    'max_tokens':10
}).encode()
req=urllib.request.Request(url, data=data)
req.add_header('Authorization',f'Bearer {apikey}')
req.add_header('Content-Type','application/json')
t0=time.time()
try:
    resp=urllib.request.urlopen(req, timeout=30, context=ssl.create_default_context())
    t=time.time()-t0
    body=json.loads(resp.read().decode())
    reply=body.get('choices',[{}])[0].get('message',{}).get('content','?')
    tokens=body.get('usage',{})
    print(f'✅ 请求成功！')
    print(f'  响应时间:  {(t*1000):.0f}ms')
    print(f'  响应内容:  {reply.strip()}')
    print(f'  Token 用量: 输入 {tokens.get(\"prompt_tokens\",\"?\")}, 输出 {tokens.get(\"completion_tokens\",\"?\")}')
except Exception as e:
    err=str(e)[:100]
    print(f'❌ 请求失败: {err}')
" 2>/dev/null
    pause
}

test_primary_latency() {
    header
    echo -e "  ${BOLD}测试主模型延迟 (3 轮取平均)${RESET}\n"
    local primary=$(python3 -c "import json;c=json.load(open('$CONFIG'));print(c.get('agents',{}).get('defaults',{}).get('model',{}).get('primary','?'))" 2>/dev/null)
    local provider="${primary%%/*}"  
    local model_name="${primary#*/}"
    echo -e "  模型: ${CYAN}${provider}/${model_name}${RESET}\n"

    python3 -c "
import json, urllib.request, ssl, time
c=json.load(open('$CONFIG'))
pdata=c.get('models',{}).get('providers',{}).get('$provider',{})
base=pdata.get('baseUrl','')
apikey=pdata.get('apiKey','')
url=base.rstrip('/')+'/chat/completions'
times=[]
for i in range(3):
    data=json.dumps({
        'model':'$model_name',
        'messages':[{'role':'user','content':'Say hello in one word'}],
        'max_tokens':5
    }).encode()
    req=urllib.request.Request(url, data=data)
    req.add_header('Authorization',f'Bearer {apikey}')
    req.add_header('Content-Type','application/json')
    t0=time.time()
    try:
        resp=urllib.request.urlopen(req, timeout=30, context=ssl.create_default_context())
        t=time.time()-t0
        times.append(t*1000)
        print(f'  第{i+1}轮: {t*1000:.0f}ms')
    except Exception as e:
        print(f'  第{i+1}轮: 失败 ({str(e)[:50]})')
if times:
    avg=sum(times)/len(times)
    mn=min(times)
    mx=max(times)
    print(f'\n  📊 平均: {avg:.0f}ms | 最快: {mn:.0f}ms | 最慢: {mx:.0f}ms')
" 2>/dev/null
    pause
}

test_fallback_batch() {
    header
    echo -e "  ${BOLD}批量测试备用模型速度${RESET}\n"
    python3 -c "
import json, urllib.request, ssl, time
c=json.load(open('$CONFIG'))
providers=c.get('models',{}).get('providers',{})
fallbacks=c.get('agents',{}).get('defaults',{}).get('model',{}).get('fallbacks',[])
ctx=ssl.create_default_context()
print(f'  {\"模型\":<40} {\"延迟\":<10} {\"状态\":<10}')
print(f'  {\"─\"*40} {\"─\"*10} {\"─\"*10}')
for fid in fallbacks:
    pn=fid.split('/')[0]
    mn='/'.join(fid.split('/')[1:])
    pdata=providers.get(pn,{})
    base=pdata.get('baseUrl','')
    apikey=pdata.get('apiKey','')
    if not base:
        print(f'  {fid:<40} {\"-\":<10} ⚠️ 无Provider')
        continue
    url=base.rstrip('/')+'/chat/completions'
    data=json.dumps({
        'model':mn,
        'messages':[{'role':'user','content':'Hi'}],
        'max_tokens':5
    }).encode()
    req=urllib.request.Request(url, data=data)
    req.add_header('Authorization',f'Bearer {apikey}')
    req.add_header('Content-Type','application/json')
    t0=time.time()
    try:
        resp=urllib.request.urlopen(req, timeout=15, context=ctx)
        t=time.time()-t0
        print(f'  {fid:<40} {t*1000:.0f}ms    ✅')
    except Exception as e:
        err=str(e)[:30]
        print(f'  {fid:<40} {\"-\":<10} ❌ {err}')
" 2>/dev/null
    pause
}
main_menu() {
    while true; do
        header
        local bcnt; bcnt=$(find "$BACKUP_DIR" -maxdepth 1 \( -name 'openclaw.json.manual-backup-*' -o -name 'openclaw-*.tar.gz' -o -name 'openclaw-safe-*.tar.gz' \) 2>/dev/null | wc -l)
        echo
        echo -e "  ${BOLD}备份数量：${GREEN}${bcnt}${RESET}"
        echo
        echo -e "  ${YELLOW}[1]${RESET} 备份当前配置 (A/B/C 三模式)"
        echo -e "  ${YELLOW}[2]${RESET} 查看备份列表"
        echo -e "  ${YELLOW}[3]${RESET} 选择备份并恢复"
        echo -e "  ${YELLOW}[4]${RESET} 重启 Gateway"
        echo -e "  ${YELLOW}[5]${RESET} 查看配置摘要"
        echo -e "  ${YELLOW}[6]${RESET} 🔧 故障排除（一键诊断+修复）"
        echo -e "  ${YELLOW}[7]${RESET} ⚡ 快速修复 (doctor --fix)"
        echo -e "  ${YELLOW}[8]${RESET} 🧠 模型管理（查看/切换/增删）"
        echo -e "  ${YELLOW}[9]${RESET} 🔬 模型测试（连通性+响应）"
        echo -e "  ${YELLOW}[0]${RESET} 退出"
        echo
        echo -ne "  ${BOLD}请选择 [0-9]: ${RESET}"
        read -r choice
        choice="${choice// /}"
        case "$choice" in
            1) backup_menu; pause ;;
            2) list_backups; pause ;;
            3)
                header; echo -e "  ${BOLD}[3] 选择备份恢复${RESET}"
                if list_backups; then
                    if select_backup; then
                        if do_restore "$SELECTED"; then
                            validate_config
                            echo; restart_gateway
                        fi
                    fi
                fi
                pause ;;
            4) restart_gateway; pause ;;
            5) show_summary; pause ;;
            6) troubleshoot; pause ;;
            7) quick_fix; pause ;;
            8) model_manager; pause ;;
            9) model_tester; pause ;;
            0) echo -e "\n  ${CYAN}再见！🐉${RESET}"; exit 0 ;;
            *) echo -e "  ${RED}无效，请输入 0-9${RESET}"; sleep 1 ;;
        esac
    done
}

# ══════════════════════════════════════════
# 入口
# ══════════════════════════════════════════
if [[ $# -ge 1 ]]; then
    case "$1" in
        backup) backup_menu ;;
        list)   list_backups ;;
        doctor|fix|repair) troubleshoot ;;
        help|--help|-h)
            echo "用法: $0 [backup|list|doctor|fix|repair|help]"
            echo "  直接运行 → 交互式菜单"
            echo "  backup   → 进入备份模式选择"
            echo "  list     → 列出所有备份"
            echo "  doctor   → 一键故障排除"
            ;;
        *) err "未知参数: $1"; echo "  运行 $0 help 查看 用法"; exit 1 ;;
    esac
else
    [[ ! -d "$OC_DIR" ]] && { err "OpenClaw 目录不存在: $OC_DIR"; exit 1; }
    main_menu
fi
