#!/bin/bash
# Prompt Logger Skill 一键安装脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=========================================="
echo "  Prompt Logger Skill 安装程序"
echo "=========================================="
echo ""

# 1. 创建目录
echo "[1/4] 创建目录..."
mkdir -p "$CLAUDE_DIR/skills/prompt-logger"
mkdir -p "$CLAUDE_DIR/hooks"

# 2. 复制 Skill 定义
echo "[2/4] 安装 Skill 定义..."
cp "$SCRIPT_DIR/skills/prompt-logger/SKILL.md" "$CLAUDE_DIR/skills/prompt-logger/"

# 3. 复制并设置 Hook 脚本权限
echo "[3/4] 安装 Hook 脚本..."
cp "$SCRIPT_DIR/hooks/session-start.sh" "$CLAUDE_DIR/hooks/"
cp "$SCRIPT_DIR/hooks/log-prompt.sh" "$CLAUDE_DIR/hooks/"
cp "$SCRIPT_DIR/hooks/log-response.sh" "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/session-start.sh"
chmod +x "$CLAUDE_DIR/hooks/log-prompt.sh"
chmod +x "$CLAUDE_DIR/hooks/log-response.sh"

# 4. 处理 settings.json
echo "[4/4] 配置 settings.json..."
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
    # 不存在则直接复制
    cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
    echo "    - 已创建新的 settings.json"
else
    # 已存在，检查是否已有 hooks 配置
    if grep -q '"hooks"' "$SETTINGS_FILE"; then
        echo ""
        echo "    ⚠️  检测到 settings.json 已包含 hooks 配置"
        echo "    请手动合并以下配置到 $SETTINGS_FILE:"
        echo ""
        cat "$SCRIPT_DIR/settings.json"
        echo ""
    else
        # 使用 jq 合并（如果有 jq）
        if command -v jq &> /dev/null; then
            TEMP_FILE=$(mktemp)
            jq -s '.[0] * .[1]' "$SETTINGS_FILE" "$SCRIPT_DIR/settings.json" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$SETTINGS_FILE"
            echo "    - 已合并 hooks 配置到现有 settings.json"
        else
            echo ""
            echo "    ⚠️  无法自动合并（需要 jq 工具）"
            echo "    请手动将以下内容添加到 $SETTINGS_FILE:"
            echo ""
            cat "$SCRIPT_DIR/settings.json"
            echo ""
        fi
    fi
fi

echo ""
echo "=========================================="
echo "  安装完成！"
echo "=========================================="
echo ""
echo "已安装文件:"
echo "  - $CLAUDE_DIR/skills/prompt-logger/SKILL.md"
echo "  - $CLAUDE_DIR/hooks/session-start.sh"
echo "  - $CLAUDE_DIR/hooks/log-prompt.sh"
echo "  - $CLAUDE_DIR/hooks/log-response.sh"
echo "  - $CLAUDE_DIR/settings.json"
echo ""
echo "重启 Claude Code 后生效。"
echo ""
