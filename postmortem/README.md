# Postmortem 尸检报告

本目录存放项目的所有 Postmortem（尸检报告），用于记录和分析历史问题，防止类似问题再次发生。

## 目录结构

```
postmortem/
├── README.md                           # 本说明文件
├── TEMPLATE.md                         # Postmortem 模板
├── PM-2026-001-cwd-vs-project-dir.md  # 具体的 Postmortem 报告
└── ...
```

## 命名规范

Postmortem 文件命名格式：`PM-YYYY-NNN-short-description.md`

- `PM`：Postmortem 前缀
- `YYYY`：年份
- `NNN`：三位数序号，从 001 开始
- `short-description`：简短的问题描述（使用连字符分隔）

## 严重级别定义

| 级别 | 定义 | 响应时间 |
|-----|------|---------|
| **Critical** | 系统完全不可用，数据丢失风险 | 立即响应 |
| **High** | 核心功能受损，影响大部分用户 | 24 小时内 |
| **Medium** | 部分功能受损，有临时解决方案 | 72 小时内 |
| **Low** | 轻微问题，不影响主要功能 | 下个迭代 |

## 工作流程

### 1. Onboarding Postmortem

新项目或新成员加入时，分析所有历史 fix commits 生成 postmortem。

### 2. Release 前检查

每次 Release 前，GitHub Workflow 自动：
1. 获取此 Release 中所有 commits
2. 调用 AI 分析是否可能触发已知的 postmortem
3. 如果检测到风险，阻止 Release 并提示修复

### 3. Release 后总结

每次 Release 后，GitHub Workflow 自动：
1. 分析此 Release 中所有 fix commits
2. 结合现有 postmortem 生成新的尸检报告
3. 提交到 postmortem 目录

## 现有 Postmortem 索引

| ID | 标题 | 严重级别 | 状态 |
|----|------|---------|------|
| [PM-2026-001](./PM-2026-001-cwd-vs-project-dir.md) | 使用 cwd 而非 CLAUDE_PROJECT_DIR 导致日志写入错误目录 | High | 已修复 |

## 检测规则汇总

以下是从所有 postmortem 中提取的检测规则，用于 CI 自动检查：

### PM-2026-001: cwd 误用检测

```bash
# 检测是否错误使用 .cwd 而非 CLAUDE_PROJECT_DIR
grep -r "\.cwd" hooks/*.sh | grep -v "CLAUDE_PROJECT_DIR"
```

## 相关链接

- [GitHub Workflow: Pre-Release Check](.github/workflows/pre-release-check.yml)
- [GitHub Workflow: Post-Release Postmortem](.github/workflows/post-release-postmortem.yml)
