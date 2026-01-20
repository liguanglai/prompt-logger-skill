#!/bin/bash
# Prompt Logger Skill - DevContainer 安装脚本
# 在宿主机运行，自动配置 devcontainer.json
#
# 使用方法:
#   curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
#   chmod +x install-devcontainer.sh
#   ./install-devcontainer.sh /path/to/your/devcontainer/project

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查参数
PROJECT_DIR="${1:-.}"
PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd)

info "配置 Prompt Logger Skill: $PROJECT_DIR"

# 检查 devcontainer.json
DEVCONTAINER_JSON="$PROJECT_DIR/.devcontainer/devcontainer.json"

if [ ! -f "$DEVCONTAINER_JSON" ]; then
    error "未找到 devcontainer.json: $DEVCONTAINER_JSON"
fi

# 检查 jq
if ! command -v jq &> /dev/null; then
    error "需要 jq 来修改 JSON 文件。请安装: brew install jq (Mac) 或 apt install jq (Linux)"
fi

# 备份
info "备份 devcontainer.json..."
cp "$DEVCONTAINER_JSON" "$DEVCONTAINER_JSON.bak"

# 检查是否已配置
if grep -q "install-in-container.sh" "$DEVCONTAINER_JSON"; then
    warn "已配置 Prompt Logger Skill，跳过"
    exit 0
fi

# 添加 postCreateCommand 和 containerEnv
info "更新 devcontainer.json..."

INSTALL_CMD="curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash"

# 读取现有配置
EXISTING_POST_CREATE=$(jq -r '.postCreateCommand // empty' "$DEVCONTAINER_JSON")

if [ -n "$EXISTING_POST_CREATE" ]; then
    # 追加到现有命令
    NEW_POST_CREATE="$EXISTING_POST_CREATE && $INSTALL_CMD"
else
    NEW_POST_CREATE="$INSTALL_CMD"
fi

# 更新 JSON
jq --arg cmd "$NEW_POST_CREATE" '
  .postCreateCommand = $cmd |
  .containerEnv = (.containerEnv // {}) + {"CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"}
' "$DEVCONTAINER_JSON" > "$DEVCONTAINER_JSON.tmp"

mv "$DEVCONTAINER_JSON.tmp" "$DEVCONTAINER_JSON"

info "=========================================="
info "配置完成！"
info "=========================================="
echo ""
info "已添加到 devcontainer.json:"
echo "  - postCreateCommand: 容器创建后自动安装"
echo "  - containerEnv.CLAUDE_PROJECT_DIR: 日志输出目录"
echo ""
info "下一步:"
info "  1. VS Code 中按 F1"
info "  2. 选择 'Dev Containers: Rebuild Container'"
echo ""
info "备份文件: $DEVCONTAINER_JSON.bak"
