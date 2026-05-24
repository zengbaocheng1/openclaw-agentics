#!/bin/bash
# openclaw-config-health-check.sh
# 检查 openclaw.json 关键字段类型，避免启动失败

CONFIG="$HOME/.openclaw/openclaw.json"

echo "🔍 检查 OpenClaw 配置健康状态..."
echo ""

# 检查文件存在
if [ ! -f "$CONFIG" ]; then
    echo "❌ 配置文件不存在: $CONFIG"
    exit 1
fi

# 用 python 做严格类型检查
python3 << 'EOF'
import json
import sys

config_path = "/home/zbc/.openclaw/openclaw.json"

try:
    with open(config_path) as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print(f"❌ JSON 解析失败: {e}")
    sys.exit(1)

errors = []

# 检查 agents.list 类型（必须是数组，不是对象）
agents = data.get("agents", {})
if not isinstance(agents, dict):
    errors.append(f"agents 应该是对象，当前类型: {type(agents).__name__}")

agent_list = agents.get("list")
if agent_list is None:
    errors.append("agents.list 不存在")
elif not isinstance(agent_list, list):
    errors.append(f"agents.list 必须是数组，当前类型: {type(agent_list).__name__}，值: {agent_list}")
else:
    print(f"✅ agents.list 类型正确: list（{len(agent_list)} 项）")

# 检查 models 类型
defaults = agents.get("defaults", {})
if not isinstance(defaults, dict):
    errors.append(f"agents.defaults 必须是对象，当前类型: {type(defaults).__name__}")
else:
    print("✅ agents.defaults 类型正确: dict")

# 检查 model 类型
model = defaults.get("model", {})
if not isinstance(model, dict):
    errors.append(f"agents.defaults.model 必须是对象，当前类型: {type(model).__name__}")
else:
    print("✅ agents.defaults.model 类型正确: dict")

# 检查 primary 模型
primary = model.get("primary")
if primary:
    print(f"✅ primary model: {primary}")

fallbacks = model.get("fallbacks", [])
if isinstance(fallbacks, list):
    print(f"✅ fallbacks ({len(fallbacks)} 个): {fallbacks}")
else:
    errors.append(f"fallbacks 必须是数组，当前类型: {type(fallbacks).__name__}")

if errors:
    print("")
    print("❌ 发现错误:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print("")
    print("✅ 配置检查通过，无类型错误")
EOF

exit $?