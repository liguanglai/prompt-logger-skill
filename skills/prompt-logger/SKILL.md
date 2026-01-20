---
name: prompt-logger
description: 自动记录所有用户提示词和 Claude 响应到项目的 claude_prompt-history-{启动日期}.md 文件。当用户询问提示词历史、想要查看之前的对话记录、或需要回顾之前的请求时使用此 Skill。
---

# Prompt Logger - 对话记录器

## 功能说明

此 Skill 通过 Hook 自动记录你与 Claude Code 交互的所有提示词和 Claude 的响应。

## 工作流程

1. **SessionStart** - Claude Code 启动时：
   - 生成会话时间戳
   - 将时间戳写入 `.claude_session_date` 文件（用于跨 hook 共享）
2. **UserPromptSubmit** - 每次提交提示词时：
   - 读取 `.claude_session_date` 获取会话时间戳
   - 追加用户提示词到对应的日志文件
3. **Stop** - Claude 完成响应后：
   - 提取 Claude 的响应内容
   - 追加响应到对应的日志文件

## 记录位置

直接在 Claude Code 启动的当前目录下：
```
<工作目录>/claude_prompt-history-20251209_113500.md
```

文件名格式：`claude_prompt-history-{YYYYMMDD_HHMMSS}.md`

## 生成的文件

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-*.md` | 对话历史记录（每次启动一个） |
| `.claude_session_date` | 会话时间戳（隐藏文件，用于内部同步） |

## 记录格式示例

```markdown
# Claude Code 对话历史记录

**会话启动时间**: 2025-12-09 11:35:00
**工作目录**: /Users/ligl/my-project

---

## 2025-12-09 11:35:22

​```
用户输入的提示词内容...
​```

### Claude 响应 (2025-12-09 11:35:45)

Claude 的响应内容会显示在这里...

---

## 2025-12-09 11:36:45

​```
第二个提示词内容...
​```

### Claude 响应 (2025-12-09 11:37:10)

Claude 的第二次响应内容...

---
```

## 查看历史记录

列出所有会话记录：
```bash
ls claude_prompt-history-*.md
```

查看特定会话：
```bash
cat claude_prompt-history-20251209_113500.md
```

## 相关文件

- 会话启动脚本: `~/.claude/hooks/session-start.sh`
- 提示词记录脚本: `~/.claude/hooks/log-prompt.sh`
- 响应记录脚本: `~/.claude/hooks/log-response.sh`
- 全局配置: `~/.claude/settings.json`

## 特性

- **全局生效** - 对所有项目目录生效
- **完整记录** - 同时记录用户提示词和 Claude 响应
- **独立文件** - 每次 Claude Code 启动创建新的记录文件
- **会话内追加** - 同一会话的所有对话追加到同一个文件
- **时间追踪** - 记录会话启动时间和每条消息的时间
