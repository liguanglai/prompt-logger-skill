#!/bin/bash
# Prompt Logger Skill - 容器内安装脚本
# 在 DevContainer 容器内运行此脚本即可完成安装
#
# 使用方法 (在容器内执行):
#   curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash
#
# 或者下载后执行:
#   curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh
#   chmod +x install-in-container.sh
#   ./install-in-container.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

info "=========================================="
info "Prompt Logger Skill 容器内安装"
info "=========================================="

# 检查 jq
if ! command -v jq &> /dev/null; then
    warn "jq 未安装，尝试安装..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v apk &> /dev/null; then
        sudo apk add jq
    elif command -v yum &> /dev/null; then
        sudo yum install -y jq
    else
        error "无法自动安装 jq，请手动安装后重试"
    fi
fi

# 确定 Claude 配置目录
CLAUDE_HOME="$HOME/.claude"
info "Claude 配置目录: $CLAUDE_HOME"

# 创建目录
mkdir -p "$CLAUDE_HOME/hooks"
mkdir -p "$CLAUDE_HOME/skills/prompt-logger"

# 下载并解压
info "下载 Prompt Logger Skill..."
cd /tmp
rm -rf prompt-logger-skill-package prompt-logger-macos.tar.gz 2>/dev/null || true
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz
tar -xzf prompt-logger-macos.tar.gz

# 复制文件
info "安装文件..."
cp prompt-logger-skill-package/hooks/*.sh "$CLAUDE_HOME/hooks/"
cp prompt-logger-skill-package/skills/prompt-logger/SKILL.md "$CLAUDE_HOME/skills/prompt-logger/"
chmod +x "$CLAUDE_HOME/hooks/"*.sh

# 清理
rm -rf prompt-logger-skill-package prompt-logger-macos.tar.gz

# 配置 hooks
info "配置 hooks..."

SETTINGS_FILE="$CLAUDE_HOME/settings.json"
HOOKS_CONFIG='{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/session-start.sh"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/log-prompt.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "'"$CLAUDE_HOME"'/hooks/log-response.sh"
          }
        ]
      }
    ]
  }
}'

if [ -f "$SETTINGS_FILE" ]; then
    if grep -q '"hooks"' "$SETTINGS_FILE"; then
        warn "settings.json 已包含 hooks 配置，跳过"
    else
        # 合并配置
        info "合并 hooks 到现有 settings.json..."
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$HOOKS_CONFIG") > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi
else
    # 创建新文件
    echo "$HOOKS_CONFIG" > "$SETTINGS_FILE"
fi

# 设置环境变量提示
info "=========================================="
info "安装完成！"
info "=========================================="
echo ""
info "已安装文件:"
ls -la "$CLAUDE_HOME/hooks/"
echo ""

# 检查 CLAUDE_PROJECT_DIR
if [ -z "$CLAUDE_PROJECT_DIR" ]; then
    warn "CLAUDE_PROJECT_DIR 环境变量未设置"
    echo ""
    info "请设置环境变量（选择一种方式）:"
    echo ""
    echo "  方式 1: 在当前 shell 中设置"
    echo "    export CLAUDE_PROJECT_DIR=\$(pwd)"
    echo ""
    echo "  方式 2: 添加到 ~/.bashrc"
    echo "    echo 'export CLAUDE_PROJECT_DIR=/workspaces/your-project' >> ~/.bashrc"
    echo ""
    echo "  方式 3: 在 devcontainer.json 中添加"
    echo '    "containerEnv": {'
    echo '      "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"'
    echo '    }'
    echo ""
else
    info "CLAUDE_PROJECT_DIR 已设置: $CLAUDE_PROJECT_DIR"
fi

echo ""
info "现在可以启动 Claude Code，对话将自动记录到工作目录"
