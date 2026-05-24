#!/bin/bash

# 广州市花都区天气预报推送脚本
TOKEN="8702978687:AAGA5hwlB8uMxwMMignLeoWcCH-fNEi6lo4"
CHAT_ID="178274859"

# 重试获取天气数据
get_weather() {
    local retries=3
    local delay=2
    local result
    
    for ((i=1; i<=retries; i++)); do
        result=$(curl -s --max-time 10 "wttr.in/Huadu+Guangzhou?lang=zh&format=j1")
        if echo "$result" | python3 -c "import json, sys; json.load(sys.stdin)" 2>/dev/null; then
            echo "$result"
            return 0
        fi
        echo "重试 $i/$retries..." >&2
        sleep $delay
    done
    return 1
}

WEATHER=$(get_weather)
if [ -z "$WEATHER" ]; then
    echo "获取天气数据失败"
    exit 1
fi

# 解析天气数据
TODAY=$(echo "$WEATHER" | python3 -c "
import json, sys
data = json.load(sys.stdin)
day = data['weather'][0]
h = day['hourly'][4]
print(f\"{h['lang_zh'][0]['value']} {day['mintempC']}~{day['maxtempC']}°C\")
")

TOMORROW=$(echo "$WEATHER" | python3 -c "
import json, sys
data = json.load(sys.stdin)
day = data['weather'][1]
h = day['hourly'][4]
print(f\"{h['lang_zh'][0]['value']} {day['mintempC']}~{day['maxtempC']}°C\")
")

DAY_AFTER=$(echo "$WEATHER" | python3 -c "
import json, sys
data = json.load(sys.stdin)
day = data['weather'][2]
h = day['hourly'][4]
print(f\"{h['lang_zh'][0]['value']} {day['mintempC']}~{day['maxtempC']}°C\")
")

MSG="🌤 广州花都区 早安天气
今天：$TODAY
明天：$TOMORROW
后天：$DAY_AFTER"

# 发送到 Telegram
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MSG}" \
    -d "parse_mode=HTML" > /dev/null

echo "天气已发送: $MSG"