#!/bin/bash
# Claude Code 提示词记录脚本（完整版）
# 在记录用户输入前，先补记上一条 Claude 响应
# 支持对话编号功能

input=$(cat)

# 提取字段
USER_PROMPT=$(echo "$input" | jq -r '.prompt // empty')
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')

# 使用 CLAUDE_PROJECT_DIR（Claude 启动目录），而不是 cwd
WORK_DIR="${CLAUDE_PROJECT_DIR:-.}"

# 如果没有 prompt，退出
[ -z "$USER_PROMPT" ] && exit 0

# 获取会话日期
SESSION_FILE="$WORK_DIR/.claude_session_date"
if [ -f "$SESSION_FILE" ]; then
    SESSION_DATE=$(cat "$SESSION_FILE")
else
    SESSION_DATE=$(date "+%Y%m%d_%H%M%S")
fi

LOG_FILE="$WORK_DIR/claude_prompt-history-${SESSION_DATE}.md"
COUNTER_FILE="$WORK_DIR/.claude_msg_counter"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 获取当前消息编号
if [ -f "$COUNTER_FILE" ]; then
    MSG_NUM=$(cat "$COUNTER_FILE")
else
    MSG_NUM=0
fi

# 创建文件头（如果不存在）
if [ ! -f "$LOG_FILE" ]; then
    DISPLAY_DATE=$(echo "$SESSION_DATE" | sed 's/_/ /;s/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3/;s/ \([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/ \1:\2:\3/')
    cat > "$LOG_FILE" << HEADER
# Claude Code 对话历史记录

**会话启动时间**: $DISPLAY_DATE
**工作目录**: $WORK_DIR

---

HEADER
fi

# === 补记上一条 Claude 响应 ===
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # 检查日志文件最后是否是用户输入（有 👤 用户 但没有对应的 🤖 Claude）
    LAST_CONTENT=$(tail -20 "$LOG_FILE" 2>/dev/null)

    # 获取最后一个用户标记和最后一个 Claude 标记的行号
    LAST_USER=$(echo "$LAST_CONTENT" | grep -n "👤 用户" | tail -1 | cut -d: -f1)
    LAST_CLAUDE=$(echo "$LAST_CONTENT" | grep -n "🤖 Claude" | tail -1 | cut -d: -f1)

    # 如果有用户输入但没有对应的 Claude 响应，或者用户输入在 Claude 响应之后
    if [ -n "$LAST_USER" ] && { [ -z "$LAST_CLAUDE" ] || [ "$LAST_USER" -gt "$LAST_CLAUDE" ]; }; then
        # 从 JSONL 文件中提取最后一条有文本内容的 assistant 消息
        LAST_RESPONSE=$(tail -r "$TRANSCRIPT_PATH" 2>/dev/null | while read -r line; do
            TYPE=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
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
                    printf '%s' "$TEXT"
                    break
                fi
            fi
        done)

        if [ -n "$LAST_RESPONSE" ]; then
            # 补记响应（使用当前编号，因为这是对上一条用户输入的响应）
            cat >> "$LOG_FILE" << RESPONSE_EOF

### 🤖 Claude #${MSG_NUM} ($TIMESTAMP)

$LAST_RESPONSE

---

RESPONSE_EOF
        fi
    fi
fi

# === 递增编号并记录当前用户提示词 ===
MSG_NUM=$((MSG_NUM + 1))
echo "$MSG_NUM" > "$COUNTER_FILE"

cat >> "$LOG_FILE" << EOF

### 👤 用户 #${MSG_NUM} ($TIMESTAMP)

$USER_PROMPT

EOF

exit 0
