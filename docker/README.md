# Docker/DevContainer 安装指南

在 Docker 容器或 VS Code DevContainer 中使用 Prompt Logger Skill。

## 文件结构

```
docker/
├── README.md              # 本说明文件
├── Dockerfile             # Docker 镜像构建文件
├── docker-compose.yml     # Docker Compose 配置
└── .devcontainer/
    └── devcontainer.json  # VS Code DevContainer 配置
```

## 方式 1: 直接使用 Dockerfile

### 构建镜像

```bash
cd prompt-logger-skill-package
docker build -f docker/Dockerfile -t claude-code-prompt-logger .
```

### 运行容器

```bash
docker run -it \
  -v /path/to/your/project:/workspace \
  -e CLAUDE_PROJECT_DIR=/workspace \
  claude-code-prompt-logger \
  /bin/bash
```

## 方式 2: 使用 Docker Compose

### 配置

1. 复制 `docker-compose.yml` 到你的项目
2. 修改 volumes 配置，指向你的项目目录

### 启动

```bash
cd prompt-logger-skill-package/docker
docker-compose up -d
docker-compose exec claude-code /bin/bash
```

## 方式 3: VS Code DevContainer

### 配置

1. 将 `.devcontainer` 文件夹复制到你的项目根目录
2. 修改 `devcontainer.json` 中的路径配置

### 使用

1. 在 VS Code 中打开你的项目
2. 按 `F1` 输入 "Reopen in Container"
3. 选择 "Dev Containers: Reopen in Container"

## 方式 4: 在现有 Dockerfile 中添加

如果你已有 Dockerfile，可以添加以下内容：

```dockerfile
# 安装 jq (JSON 解析工具)
RUN apt-get update && apt-get install -y jq && rm -rf /var/lib/apt/lists/*

# 下载并安装 Prompt Logger Skill
RUN curl -LO https://github.com/liguanglai/macos_configs/releases/download/v1.1.0/prompt-logger-macos-v1.1.0.tar.gz \
    && tar -xzf prompt-logger-macos-v1.1.0.tar.gz \
    && cd prompt-logger-skill-package \
    && mkdir -p /root/.claude/hooks /root/.claude/skills/prompt-logger \
    && cp hooks/*.sh /root/.claude/hooks/ \
    && cp skills/prompt-logger/SKILL.md /root/.claude/skills/prompt-logger/ \
    && cp settings.json /root/.claude/settings.json \
    && chmod +x /root/.claude/hooks/*.sh \
    && cd .. \
    && rm -rf prompt-logger-skill-package prompt-logger-macos-v1.1.0.tar.gz

# 设置环境变量
ENV CLAUDE_PROJECT_DIR=/workspace
```

## 环境变量

| 变量 | 说明 | 默认值 |
|-----|------|-------|
| `CLAUDE_PROJECT_DIR` | Claude Code 项目目录 | `/workspace` |

## 日志文件位置

日志文件会生成在 `CLAUDE_PROJECT_DIR` 目录下：
- `claude_prompt-history-YYYYMMDD_HHMMSS.md` - 对话历史
- `.claude_session_date` - 会话时间戳
- `.claude_msg_counter` - 消息编号计数器

## 常见问题

### 1. 日志文件没有生成

检查：
- `CLAUDE_PROJECT_DIR` 环境变量是否正确设置
- 目录是否有写入权限
- `jq` 是否已安装

```bash
# 检查 jq
which jq

# 检查环境变量
echo $CLAUDE_PROJECT_DIR

# 检查目录权限
ls -la $CLAUDE_PROJECT_DIR
```

### 2. Hooks 没有执行

检查 hooks 文件权限：

```bash
ls -la ~/.claude/hooks/
# 确保有执行权限 (x)
```

### 3. Windows 容器

如果使用 Windows 容器，请使用 PowerShell 版本的脚本：
- 将 `hooks/*.ps1` 复制到容器
- 修改 `settings.json` 中的命令为 PowerShell 格式

## 验证安装

```bash
# 检查文件是否存在
ls -la ~/.claude/hooks/
ls -la ~/.claude/skills/prompt-logger/
cat ~/.claude/settings.json

# 测试 jq
echo '{"test": "ok"}' | jq -r '.test'
```
