#!/bin/bash
# OpenClaw System Resource Monitor
# 检查：Gateway存活、磁盘、内存、ERROR日志

LOG_DIR="$HOME/.openclaw/maintenance/logs"
HOST="localhost:18789"
ALERT=0
MSG=""

# 1. Gateway 存活检查
if curl -sf --max-time 5 "http://$HOST/health" | grep -q '"ok":true'; then
    GATEWAY_STATUS="✅ 正常"
else
    PID=$(pgrep -f "openclaw" | head -1)
    if [ -n "$PID" ]; then
        GATEWAY_STATUS="⚠️ 健康端点异常但进程存在(pid=$PID)"
    else
        GATEWAY_STATUS="❌ Gateway已停止"
        ALERT=1
    fi
fi

# 2. 磁盘检查（根分区）
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_PCT" -ge 90 ]; then
    DISK_STATUS="❌ 磁盘使用 ${DISK_PCT}%"
    ALERT=1
elif [ "$DISK_PCT" -ge 80 ]; then
    DISK_STATUS="⚠️ 磁盘使用 ${DISK_PCT}%"
else
    DISK_STATUS="✅ 磁盘使用 ${DISK_PCT}%"
fi

# 3. 内存检查
AVAIL_MB=$(free -m | awk 'NR==2{print $7}')
if [ "$AVAIL_MB" -lt 500 ]; then
    MEM_STATUS="⚠️ 可用内存仅 ${AVAIL_MB}MB"
    ALERT=1
else
    MEM_STATUS="✅ 可用内存 ${AVAIL_MB}MB"
fi

# 4. recent ERROR 日志检查
ERROR_COUNT=0
if [ -d "$LOG_DIR" ]; then
    ERROR_COUNT=$(find "$LOG_DIR" -name "*.log" -mmin -30 -exec grep -l "ERROR" {} \; 2>/dev/null | wc -l)
fi
if [ "$ERROR_COUNT" -gt 0 ]; then
    LOG_STATUS="⚠️ 近30分钟 $ERROR_COUNT 个ERROR日志"
else
    LOG_STATUS="✅ 无ERROR日志"
fi

# 5. Gateway 运行时长
UPTIME=$(ps -o etime= -p $(pgrep -f "openclaw" | head -1) 2>/dev/null | xargs)
if [ -n "$UPTIME" ]; then
    UPTIME_STATUS="运行时间: $UPTIME"
else
    UPTIME_STATUS="无法获取运行时长"
fi

# 输出结果
echo "[$(date '+%Y-%m-%d %H:%M')] OpenClaw 健康检查"
echo "Gateway: $GATEWAY_STATUS"
echo "磁盘: $DISK_STATUS"
echo "内存: $MEM_STATUS"
echo "日志: $LOG_STATUS"
echo "$UPTIME_STATUS"

# 异常时写入告警日志
if [ "$ALERT" -eq 1 ]; then
    echo "[$(date)] ALERT: Gateway=$GATEWAY_STATUS Disk=${DISK_PCT}% Mem=${AVAIL_MB}MB" >> "$LOG_DIR/health-alerts.log"
fi