# Windows PowerShell Hook 修复汇总

## 修复日期
2026-01-20

## 问题描述

prompt-logger skill 在 Windows 上无法正常工作，用户提示词未被记录到日志文件。

## 问题现象

1. 运行 `/prompt-logger` skill 测试时，日志文件未生成
2. Hook 脚本执行时报错：`Parameter 'Path' cannot be bound because it is null`
3. `.claude_session_date` 会话文件未创建

## 根因分析

### 原始代码问题

```powershell
# session-start.ps1 原始代码
$WorkDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }
```

### 问题原因

1. **环境变量未设置**：`$env:CLAUDE_PROJECT_DIR` 不是 Claude Code 设置的环境变量
2. **Get-Location 返回空**：当 PowerShell 作为子进程通过 stdin 管道调用时，`Get-Location` 返回 null
3. **中文注释编码问题**：脚本中的中文注释在某些情况下导致解析错误

### 正确方式

Claude Code 在调用 hook 时，会通过 stdin 传递 JSON 数据，其中包含 `cwd` 字段：

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "C:/Users/User/project",
  "permission_mode": "default",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "用户输入的提示词"
}
```

## 修复方案

### session-start.ps1 修复

```powershell
# 从 stdin 读取 JSON 输入获取工作目录
$input_text = [Console]::In.ReadToEnd()
$WorkDir = $null

try {
    $json = $input_text | ConvertFrom-Json
    if ($json.cwd) {
        $WorkDir = $json.cwd
    }
} catch {}

# 后备方案
if ([string]::IsNullOrEmpty($WorkDir)) {
    if ($env:CLAUDE_PROJECT_DIR) {
        $WorkDir = $env:CLAUDE_PROJECT_DIR
    } elseif ($PWD) {
        $WorkDir = $PWD.Path
    } else {
        try {
            $WorkDir = [System.IO.Directory]::GetCurrentDirectory()
        } catch {}
    }
}

# 最终后备
if ([string]::IsNullOrEmpty($WorkDir)) {
    $WorkDir = $env:USERPROFILE
}
```

### log-prompt.ps1 修复

```powershell
# 从解析的 JSON 中提取 cwd
$WorkDir = $data.cwd

# 后备链（同上）
if ([string]::IsNullOrEmpty($WorkDir)) {
    # ... 后备方案
}
```

## 调试过程

### 1. 初步排查

```powershell
# 手动测试 session-start.ps1
cd "C:\Users\User\01.workspace"
powershell -ExecutionPolicy Bypass -File "C:\Users\User\.claude\hooks\session-start.ps1"
# 报错：Join-Path: Parameter 'Path' cannot be bound because it is null
```

### 2. 添加调试输出

```powershell
Write-Host "DEBUG: CWD=$env:CWD"
Write-Host "DEBUG: CLAUDE_PROJECT_DIR=$env:CLAUDE_PROJECT_DIR"
Write-Host "DEBUG: PWD=$PWD"
Write-Host "DEBUG: GetCurrentDirectory=$([System.IO.Directory]::GetCurrentDirectory())"
```

输出结果：
```
DEBUG: CWD=
DEBUG: CLAUDE_PROJECT_DIR=
DEBUG: PWD=C:\Users\User\01.workspace
DEBUG: GetCurrentDirectory=C:\Users\User\01.workspace
```

### 3. 发现管道输入问题

通过管道传递 JSON 时，工作目录获取失败：

```powershell
echo '{"prompt":"test"}' | powershell -File script.ps1
# WorkDir 为空
```

### 4. 确认 JSON 输入格式

查阅 Claude Code 文档，确认 hook 接收的 JSON 包含 `cwd` 字段。

### 5. 测试修复

```powershell
echo '{"prompt":"test","cwd":"C:/Users/User/01.workspace"}' | powershell -File log-prompt.ps1
# 成功！
```

## 修改的文件

| 文件 | 修改内容 |
|------|----------|
| `hooks/session-start.ps1` | 从 JSON 输入读取 cwd，添加后备链 |
| `hooks/log-prompt.ps1` | 从 JSON 数据提取 cwd，添加后备链，英文注释 |

## Git 提交

```
15ccd31 docs: Update postmortem with commit hash
1e9c43c fix(windows): Use cwd from JSON input instead of env variable
```

## 经验教训

1. **不要假设环境变量存在** - 应该先验证再使用
2. **PowerShell 子进程上下文不同** - 通过管道调用时，工作目录等上下文可能丢失
3. **优先使用应用传递的数据** - Claude Code 通过 JSON 传递所有必要信息，应该优先使用
4. **避免中文注释** - 在跨平台脚本中使用英文注释，避免编码问题
5. **添加完整的后备链** - 确保在各种情况下都能获取到有效的工作目录

## 后续改进

- [ ] 添加 Windows CI/CD 测试
- [ ] 在 README 中记录 JSON 输入格式
- [ ] 考虑添加错误日志功能，便于调试
