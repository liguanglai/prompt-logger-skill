# Docker/DevContainer 安装指南

在 Docker 容器或 VS Code DevContainer 中使用 Prompt Logger Skill。

## 快速安装

### 方式 1: 自动配置（推荐）

在宿主机运行安装脚本，自动配置 `devcontainer.json`：

**macOS / Linux:**
```bash
curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.sh
chmod +x install-devcontainer.sh
./install-devcontainer.sh /path/to/your/devcontainer/project
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
.\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"
```

然后在 VS Code 中 **Rebuild Container**。

### 方式 2: 容器内安装

进入容器后执行：

```bash
curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash
```

注意：此方式需要设置环境变量 `CLAUDE_PROJECT_DIR`，且容器重建后需重新安装。

### 方式 3: 手动配置

在 `devcontainer.json` 中添加：

```json
{
  "postCreateCommand": "curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash",
  "containerEnv": {
    "CLAUDE_PROJECT_DIR": "${containerWorkspaceFolder}"
  }
}
```

## 环境变量

| 变量 | 说明 | 必须 |
|-----|------|-----|
| `CLAUDE_PROJECT_DIR` | 日志输出目录 | 是 |

## 日志文件位置

日志文件会生成在 `CLAUDE_PROJECT_DIR` 目录下：

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-YYYYMMDD_HHMMSS.md` | 对话历史 |
| `.claude_session_date` | 会话时间戳 |
| `.claude_msg_counter` | 消息编号计数器 |

## 常见问题

### 1. 日志文件没有生成

检查：
```bash
# 检查环境变量
echo $CLAUDE_PROJECT_DIR

# 检查 jq 是否安装
which jq

# 检查 hooks 是否安装
ls -la ~/.claude/hooks/
```

### 2. 容器重建后需要重新安装

使用方式 1（自动配置）或方式 3（手动配置 postCreateCommand），容器重建时会自动安装。

### 3. 验证安装

```bash
# 检查文件
ls -la ~/.claude/hooks/
ls -la ~/.claude/skills/prompt-logger/
cat ~/.claude/settings.json

# 测试 jq
echo '{"test": "ok"}' | jq -r '.test'
```

## 参考配置文件

本目录包含参考配置文件：

| 文件 | 说明 |
|------|------|
| `Dockerfile` | Docker 镜像构建示例 |
| `docker-compose.yml` | Docker Compose 配置示例 |
| `.devcontainer/devcontainer.json` | VS Code DevContainer 配置示例 |
