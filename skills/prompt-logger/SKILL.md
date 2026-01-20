---
name: prompt-logger
description: 自动记录所有用户提示词和 Claude 响应到项目的 claude_prompt-history-{启动日期}.md 文件。当用户询问提示词历史、想要查看之前的对话记录、或需要回顾之前的请求时使用此 Skill。
version: 1.1.0
author: liguanglai
---

# Prompt Logger - 对话记录器

## 功能说明

此 Skill 通过 Hook 自动记录你与 Claude Code 交互的所有提示词和 Claude 的响应。

## 特性

- 自动记录用户提示词和 Claude 响应
- 对话编号功能 (#1, #2, ...)
- 使用 emoji 区分用户 (👤) 和 Claude (🤖)
- 每个会话生成独立的日志文件

## 工作流程

1. **SessionStart** - Claude Code 启动时：
   - 生成会话时间戳
   - 初始化消息计数器
   - 创建日志文件头部

2. **UserPromptSubmit** - 每次提交提示词时：
   - 补记上一条 Claude 响应（如有）
   - 记录用户提示词（带编号）

3. **Stop** - Claude 完成响应后：
   - 提取 Claude 的响应内容
   - 追加响应到日志文件

## 记录位置

日志文件生成在 `CLAUDE_PROJECT_DIR` 环境变量指定的目录：
```
$CLAUDE_PROJECT_DIR/claude_prompt-history-20260119_170000.md
```

文件名格式：`claude_prompt-history-{YYYYMMDD_HHMMSS}.md`

## 生成的文件

| 文件 | 说明 |
|------|------|
| `claude_prompt-history-*.md` | 对话历史记录 |
| `.claude_session_date` | 会话时间戳（隐藏文件） |
| `.claude_msg_counter` | 消息编号计数器（隐藏文件） |

## 记录格式示例

```markdown
# Claude Code 对话历史记录

**会话启动时间**: 2026-01-19 17:00:00
**工作目录**: /Users/ligl/my-project

---

### 👤 用户 #1 (2026-01-19 17:00:15)

帮我写一个 Hello World 程序

### 🤖 Claude #1 (2026-01-19 17:00:30)

好的，这是一个简单的 Python Hello World 程序：
...

---

### 👤 用户 #2 (2026-01-19 17:01:00)

改成 JavaScript 版本

### 🤖 Claude #2 (2026-01-19 17:01:15)

好的，这是 JavaScript 版本：
...
```

## 查看历史记录

列出所有会话记录：
```bash
ls claude_prompt-history-*.md
```

查看特定会话：
```bash
cat claude_prompt-history-20260119_170000.md
```

## 相关文件

- 会话启动脚本: `~/.claude/hooks/session-start.sh`
- 提示词记录脚本: `~/.claude/hooks/log-prompt.sh`
- 响应记录脚本: `~/.claude/hooks/log-response.sh`
- 全局配置: `~/.claude/settings.json`
