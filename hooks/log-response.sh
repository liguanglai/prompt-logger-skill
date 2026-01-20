#!/bin/bash
# Claude Code 响应记录脚本
# 从 transcript_path 读取对话记录，提取最后的 assistant 响应
# 支持对话编号功能

# 从 stdin 读取 JSON 输入
input=$(cat)

# 提取 transcript_path
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# macOS 兼容：使用 tail -r 代替 tac
# 从 JSONL 文件中提取最后一条 assistant 消息的文本内容
RESPONSE=$(tail -r "$TRANSCRIPT_PATH" | while read -r line; do
    TYPE=$(echo "$line" | jq -r '.type // empty')
    if [ "$TYPE" = "assistant" ]; then
        TEXT=$(echo "$line" | jq -r '
            .message.content
            | if type == "array" then
                map(select(.type == "text") | .text) | join("\n")
              else
                empty
              end
        ' 2>/dev/null)
        if [ -n "$TEXT" ]; then
            echo "$TEXT"
            break
        fi
    fi
done)

# 如果没有内容，退出
if [ -z "$RESPONSE" ]; then
    exit 0
fi

# 使用 CLAUDE_PROJECT_DIR（Claude 启动目录），而不是 cwd
WORK_DIR="${CLAUDE_PROJECT_DIR:-.}"

# 获取会话启动日期
SESSION_FILE="$WORK_DIR/.claude_session_date"
if [ -f "$SESSION_FILE" ]; then
    SESSION_DATE=$(cat "$SESSION_FILE")
else
    SESSION_DATE=$(date "+%Y%m%d_%H%M%S")
fi

LOG_FILE="$WORK_DIR/claude_prompt-history-${SESSION_DATE}.md"
COUNTER_FILE="$WORK_DIR/.claude_msg_counter"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 获取当前消息编号（不递增，因为这是对当前用户输入的响应）
if [ -f "$COUNTER_FILE" ]; then
    MSG_NUM=$(cat "$COUNTER_FILE")
else
    MSG_NUM=1
fi

# 追加 Claude 响应记录
cat >> "$LOG_FILE" << RESPONSE_EOF

### 🤖 Claude #${MSG_NUM} ($TIMESTAMP)

$RESPONSE

---

RESPONSE_EOF

exit 0
