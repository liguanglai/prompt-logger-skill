# PM-2026-001: 使用 cwd 而非 CLAUDE_PROJECT_DIR 导致日志写入错误目录

## 基本信息

| 字段 | 内容 |
|-----|------|
| **ID** | PM-2026-001 |
| **标题** | 使用 cwd 而非 CLAUDE_PROJECT_DIR 导致日志写入错误目录 |
| **严重级别** | High |
| **发现时间** | 2026-01-19 |
| **修复时间** | 2026-01-19 |
| **修复 Commit** | e6589ca |
| **影响范围** | macOS/Linux 用户的 Claude 响应日志记录功能 |

## 问题摘要

`log-response.sh` 脚本使用 JSON 输入中的 `.cwd` 字段作为工作目录，而非 `CLAUDE_PROJECT_DIR` 环境变量。当用户在子目录中执行命令（如 git 操作）后，Stop hook 会将 Claude 响应写入到错误的目录。

## 时间线

| 时间 | 事件 |
|-----|------|
| 2026-01-19 17:04 | 用户报告发现 macos_configs 目录下有 Claude 响应，但项目目录下没有 |
| 2026-01-19 17:05 | 开始调查，对比两个目录的日志文件 |
| 2026-01-19 17:07 | 确定根因：log-response.sh 使用了 .cwd 而非 CLAUDE_PROJECT_DIR |
| 2026-01-19 17:08 | 修复并部署 |

## 根因分析 (Root Cause Analysis)

### 直接原因

`log-response.sh` 第 41 行使用了 JSON 输入中的 `.cwd` 字段：
```bash
WORK_DIR=$(echo "$input" | jq -r '.cwd // "."')
```

而 `log-prompt.sh` 使用的是环境变量：
```bash
WORK_DIR="${CLAUDE_PROJECT_DIR:-.}"
```

### 根本原因

1. **不一致的目录获取方式**：两个脚本使用不同的方式获取工作目录
2. **对 cwd 和 CLAUDE_PROJECT_DIR 的理解偏差**：
   - `cwd`：当前 shell 的工作目录，会随 `cd` 命令或工具执行位置改变
   - `CLAUDE_PROJECT_DIR`：Claude Code 启动时的项目根目录，保持不变
3. **缺乏代码审查**：在添加 log-response.sh 时，没有与 log-prompt.sh 保持一致

### 代码变更

```diff
- # 获取当前工作目录
- WORK_DIR=$(echo "$input" | jq -r '.cwd // "."')
+ # 使用 CLAUDE_PROJECT_DIR（Claude 启动目录），而不是 cwd
+ WORK_DIR="${CLAUDE_PROJECT_DIR:-.}"
```

## 影响评估

### 影响范围
- 所有使用 Stop hook 记录 Claude 响应的 macOS/Linux 用户
- 当用户在会话中执行涉及子目录的命令时

### 影响程度
- Claude 响应被写入到错误的目录（子目录）
- 导致项目根目录下的日志文件缺少 Claude 响应
- 日志不完整，影响用户查看对话历史

## 经验教训 (Lessons Learned)

### 做得好的地方
- 问题发现后快速定位根因
- 有对比参照（log-prompt.sh 的正确实现）

### 需要改进的地方
- 需要统一目录获取方式的规范
- 新增脚本时需要检查与现有脚本的一致性
- 应该在修改后进行完整的端到端测试

## 预防措施 (Action Items)

| 优先级 | 措施 | 负责人 | 截止日期 | 状态 |
|-------|------|-------|---------|------|
| P0 | 统一所有脚本使用 CLAUDE_PROJECT_DIR | - | 2026-01-19 | 已完成 |
| P1 | 添加自动检测规则到 CI | - | 待定 | 待处理 |
| P2 | 编写开发规范文档 | - | 待定 | 待处理 |

## 检测规则 (Detection Rules)

### 代码模式

以下代码模式可能触发此类问题：

```bash
# 危险模式 - 使用 .cwd 作为工作目录
WORK_DIR=$(echo "$input" | jq -r '.cwd // "."')

# 危险模式 - 直接使用 cwd 变量
WORK_DIR="$cwd"
```

### 检测关键词
- `.cwd`
- `jq -r '.cwd`
- `$cwd`（非 CLAUDE_PROJECT_DIR 上下文）

### 自动检测脚本

```bash
#!/bin/bash
# 检测脚本中是否错误使用 cwd 而非 CLAUDE_PROJECT_DIR

HOOKS_DIR="prompt-logger-skill-package/hooks"

# 检查是否使用 .cwd 获取工作目录
if grep -r "\.cwd" "$HOOKS_DIR"/*.sh 2>/dev/null | grep -v "CLAUDE_PROJECT_DIR"; then
    echo "WARNING: 发现使用 .cwd 而非 CLAUDE_PROJECT_DIR 的代码"
    echo "请确保工作目录使用 CLAUDE_PROJECT_DIR 环境变量"
    exit 1
fi

echo "OK: 未发现 cwd 误用问题"
exit 0
```

## 相关链接

- 修复 Commit: https://github.com/liguanglai/macos_configs/commit/e6589ca
- 相关 Postmortem: 无
