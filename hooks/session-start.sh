#!/bin/bash
# Claude Code 会话启动脚本
# 设置会话创建日期，写入文件以便其他 hook 读取

# 生成会话日期时间戳
SESSION_DATE=$(date "+%Y%m%d_%H%M%S")

# 获取工作目录
WORK_DIR="${CLAUDE_PROJECT_DIR:-.}"

# 将会话日期写入项目目录下的隐藏文件
SESSION_FILE="$WORK_DIR/.claude_session_date"
echo "$SESSION_DATE" > "$SESSION_FILE"

# 同时保留环境变量方式（如果支持）
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo "export CLAUDE_SESSION_DATE=$SESSION_DATE" >> "$CLAUDE_ENV_FILE"
fi

exit 0
