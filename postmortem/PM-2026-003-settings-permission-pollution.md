# Postmortem: Settings Local 权限列表污染

## 基本信息

| 字段 | 内容 |
|-----|------|
| **ID** | PM-2026-003 |
| **标题** | Settings Local 权限列表被完整命令污染导致启动失败 |
| **严重级别** | High |
| **发现时间** | 2026-01-20 |
| **修复时间** | 2026-01-20 |
| **修复 Commit** | 待提交 |
| **影响范围** | Claude Code 完全无法启动 |

## 问题摘要

`.claude/settings.local.json` 的 `permissions.allow` 数组中被写入了完整的 bash 命令字符串（包含 heredoc），而非有效的权限模式规则，导致 Claude Code 解析配置失败无法启动。

## 时间线

| 时间 | 事件 |
|-----|------|
| 2026-01-20 17:20 | 用户报告 Claude Code 启动失败 |
| 2026-01-20 17:21 | 检查 settings.local.json 发现问题 |
| 2026-01-20 17:21 | 清理无效权限条目，恢复正常 |

## 根因分析 (Root Cause Analysis)

### 直接原因

`settings.local.json` 中存在以下无效的权限条目：

```json
"Bash(git commit -m \"$(cat <<'EOF'\n...\nEOF\n)\")"
"Bash(gh release edit v1.1.0 --notes \"$(cat <<'EOF'\n...[超长的 release notes]...\nEOF\n)\")"
```

这些是**完整的 bash 命令字符串**，包含了 heredoc 语法和转义字符，而不是 Claude Code 期望的**权限模式规则**。

### 根本原因

1. **用户授权机制误解**：当用户在 Claude Code 中批准执行某个 bash 命令时，该命令会被自动添加到 `settings.local.json` 的 allow 列表中
2. **超长命令问题**：使用 heredoc 语法的 `git commit` 和 `gh release edit` 命令非常长（包含完整的 release notes），被原样存储
3. **模式解析失败**：Claude Code 尝试将这些字符串解析为权限模式（如 `Bash(command:*)`），但其中包含的特殊字符 `(`, `)`, `:`, `*` 等与模式语法冲突

### 错误的权限条目示例

```json
// 错误 - 完整命令被存储
"Bash(gh release edit v1.1.0 --notes \"$(cat <<'EOF'\n## Prompt Logger...\nEOF\n)\")"

// 正确 - 应该是模式规则
"Bash(gh release edit:*)"
```

### 代码变更

```diff
 {
   "permissions": {
     "allow": [
       "Bash(git clone:*)",
       "Bash(chmod:*)",
       "Bash(bash:*)",
       "Bash(jq:*)",
       "Bash(git add:*)",
-      "Bash(git commit -m \"$(cat <<'EOF'\\nfeat: 添加...\\nEOF\\n)\")",
+      "Bash(git commit:*)",
       "Bash(git push:*)",
-      "Bash(git commit -m \"$(cat <<'EOF'\\nfeat: 改进...\\nEOF\\n)\")",
-      "Bash(git commit -m \"$(cat <<'EOF'\\nfeat: 添加 Windows...\\nEOF\\n)\")",
-      "Bash(git commit:*)",
+      "Bash(git pull:*)",
+      "Bash(git tag:*)",
       "Bash(tar -czvf:*)",
-      "Bash(git tag:*)",
       "Bash(gh release create:*)",
-      "Bash(ls:*)",
       "Bash(gh release view:*)",
       "Bash(gh release upload:*)",
-      "Bash(gh release edit v1.1.0 --notes \"$(cat <<'EOF'\\n## Prompt Logger...\\nEOF\\n)\")",
-      "Bash(gh release edit v1.1.0 --notes \"$(cat <<'EOF'\\n## Prompt Logger...\\nEOF\\n)\")",
-      "Bash(gh release edit v1.1.0 --notes \"$(cat <<'EOF'\\n## Prompt Logger...\\nEOF\\n)\")",
-      "Bash(git pull:*)",
+      "Bash(gh release edit:*)",
+      "Bash(ls:*)",
       "Bash(bash -n:*)",
       "Bash(echo:*)",
       "Bash(file:*)",
       "Bash(xxd:*)"
     ]
   }
 }
```

## 影响评估

### 影响范围
- Claude Code 完全无法启动
- 项目级别配置文件损坏

### 影响程度
- **严重**：用户无法使用 Claude Code 进行任何操作
- 必须手动选择 "Continue without these settings" 或手动修复配置文件

## 经验教训 (Lessons Learned)

### 做得好的地方
- 错误信息清晰指出了配置文件位置和问题类型
- 系统提供了 "Continue without these settings" 的降级选项

### 需要改进的地方
- 批准 bash 命令时，系统应该转换为模式规则而非存储完整命令
- 超长命令（特别是包含 heredoc 的命令）应该有特殊处理
- 用户应该使用一次性批准而非永久存储敏感命令

## 预防措施 (Action Items)

| 优先级 | 措施 | 负责人 | 截止日期 | 状态 |
|-------|------|-------|---------|------|
| P1 | 使用 heredoc 命令时选择"仅本次允许"而非"始终允许" | 用户 | - | 建议 |
| P2 | 定期检查 settings.local.json 清理无效条目 | 用户 | - | 建议 |
| P2 | 对于复杂命令，预先配置模式规则而非依赖自动添加 | 用户 | - | 建议 |

## 检测规则 (Detection Rules)

### 代码模式

权限条目包含以下特征时可能有问题：
- 包含 `<<'EOF'` 或 `<<EOF` (heredoc 语法)
- 包含 `\n` (换行符转义)
- 条目长度超过 100 字符
- 包含完整的 release notes 或 commit message

### 检测关键词
- `<<'EOF'`
- `<<EOF`
- `\nEOF\n`
- `--notes`
- `--message`

### 自动检测脚本

```bash
#!/bin/bash
# 检测 settings.local.json 中的超长或可疑权限条目

SETTINGS_FILE=".claude/settings.local.json"

if [ -f "$SETTINGS_FILE" ]; then
    # 检查是否包含 heredoc 语法
    if grep -q "EOF" "$SETTINGS_FILE"; then
        echo "警告: 发现可能的 heredoc 语法污染"
        echo "建议检查 $SETTINGS_FILE 中的 permissions.allow 数组"
    fi

    # 检查超长行
    if awk 'length > 200' "$SETTINGS_FILE" | grep -q .; then
        echo "警告: 发现超长权限条目"
    fi
fi
```

## 相关链接

- [Claude Code 权限配置文档](https://docs.anthropic.com/claude-code/permissions)
- PM-2026-001: cwd vs project dir 问题
- PM-2026-002: Windows workdir null 问题
