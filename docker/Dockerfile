# Prompt Logger Skill - Docker 安装示例
# 用于在 Docker 容器中预装 Prompt Logger Skill

# 基础镜像 (根据需要修改)
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

# 安装依赖
RUN apt-get update && apt-get install -y \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建 Claude 配置目录
RUN mkdir -p /root/.claude/hooks \
    /root/.claude/skills/prompt-logger

# 复制 Skill 文件
COPY hooks/session-start.sh /root/.claude/hooks/
COPY hooks/log-prompt.sh /root/.claude/hooks/
COPY hooks/log-response.sh /root/.claude/hooks/
COPY skills/prompt-logger/SKILL.md /root/.claude/skills/prompt-logger/
COPY settings.json /root/.claude/settings.json

# 设置执行权限
RUN chmod +x /root/.claude/hooks/*.sh

# 设置工作目录
WORKDIR /workspace

# 环境变量 (可在运行时覆盖)
ENV CLAUDE_PROJECT_DIR=/workspace

# 验证安装
RUN echo "Prompt Logger Skill installed:" && \
    ls -la /root/.claude/hooks/ && \
    ls -la /root/.claude/skills/prompt-logger/
