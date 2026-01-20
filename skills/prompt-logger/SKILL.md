---
name: prompt-logger
description: 自动记录所有用户提示词到项目的 claude_prompt-history-{启动日期}.md 文件。当用户询问提示词历史、想要查看之前的对话记录、或需要回顾之前的请求时使用此 Skill。
version: 1.2.0
author: ligl
---

# Prompt Logger - 对话记录器

## 功能说明

此 Skill 通过 Hook 自动记录你与 Claude Code 交互的提示词和响应。

## 平台差异

### Windows
- 使用 PowerShell 脚本记录用户提示词
- 使用 `auto-export.js` 读取 Claude Code transcript 自动导出完整对话
- 生成两个文件：
  - `claude_prompt-history-*.md` - 用户提示词记录
  - `chat-*.md` - 完整对话导出（含 Claude 响应）

### Mac/Linux/容器
- 使用 Bash 脚本记录用户提示词和 Claude 响应
- 对话编号功能 (#1, #2, ...)
- 使用 emoji 区分用户 (👤) 和 Claude (🤖)

## 工作流程

### Windows

1. **SessionStart** - 生成会话时间戳
2. **UserPromptSubmit** - 记录用户提示词
3. **Stop/SessionEnd** - 调用 auto-export.js 导出完整对话

### Mac/Linux/容器

1. **SessionStart** - 生成会话时间戳，初始化消息计数器
2. **UserPromptSubmit** - 补记上一条 Claude 响应，记录用户提示词
3. **Stop** - 提取 Claude 响应，追加到日志文件

## 生成的文件

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-*.md` | 用户提示词记录 |
| `chat-*.md` | 完整对话导出 (Windows) |
| `.claude_session_date` | 会话时间戳（隐藏文件） |
| `.claude_msg_counter` | 消息编号计数器（Mac/Linux） |

## 查看历史记录

```bash
# 列出所有会话记录
ls claude_prompt-history-*.md

# 查看完整对话 (Windows)
ls chat-*.md
```

## 相关文件

### Windows
- `~/.claude/hooks/session-start.ps1`
- `~/.claude/hooks/log-prompt.ps1`
- `~/.claude/hooks/auto-export.js`
- `~/.claude/settings.json`

### Mac/Linux/容器
- `~/.claude/hooks/session-start.sh`
- `~/.claude/hooks/log-prompt.sh`
- `~/.claude/hooks/log-response.sh`
- `~/.claude/settings.json`
