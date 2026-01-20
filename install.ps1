# Prompt Logger Skill 安装脚本 (Windows PowerShell)
# 用法: .\install.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== Prompt Logger Skill 安装程序 (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# 获取脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Claude 配置目录
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"

# 1. 创建必要的目录
Write-Host "[1/4] 创建目录结构..." -ForegroundColor Yellow
$HooksDir = Join-Path $ClaudeDir "hooks"
$SkillsDir = Join-Path $ClaudeDir "skills\prompt-logger"

if (-not (Test-Path $HooksDir)) { New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null }
if (-not (Test-Path $SkillsDir)) { New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null }

# 2. 复制 Skill 文档
Write-Host "[2/4] 安装 Skill 文档..." -ForegroundColor Yellow
Copy-Item (Join-Path $ScriptDir "skills\prompt-logger\SKILL.md") $SkillsDir -Force

# 3. 复制 Hook 脚本
Write-Host "[3/4] 安装 Hook 脚本..." -ForegroundColor Yellow
Copy-Item (Join-Path $ScriptDir "hooks\session-start.ps1") $HooksDir -Force
Copy-Item (Join-Path $ScriptDir "hooks\log-prompt.ps1") $HooksDir -Force

# 4. 配置 settings.json
Write-Host "[4/4] 配置 settings.json..." -ForegroundColor Yellow
$SettingsFile = Join-Path $ClaudeDir "settings.json"

# 新的 hooks 配置
$NewHooks = @{
    hooks = @{
        SessionStart = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.claude\hooks\session-start.ps1`""
                    }
                )
            }
        )
        UserPromptSubmit = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -ExecutionPolicy Bypass -File `"$env:USERPROFILE\.claude\hooks\log-prompt.ps1`""
                    }
                )
            }
        )
    }
}

if (Test-Path $SettingsFile) {
    # 读取现有配置
    $ExistingSettings = Get-Content $SettingsFile -Raw | ConvertFrom-Json

    # 合并 hooks 配置
    if (-not $ExistingSettings.hooks) {
        $ExistingSettings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{} -Force
    }

    # 更新 hooks
    $ExistingSettings.hooks = $NewHooks.hooks

    # 保存
    $ExistingSettings | ConvertTo-Json -Depth 10 | Out-File $SettingsFile -Encoding UTF8
} else {
    # 创建新配置
    $NewHooks | ConvertTo-Json -Depth 10 | Out-File $SettingsFile -Encoding UTF8
}

Write-Host ""
Write-Host "=== 安装完成! ===" -ForegroundColor Green
Write-Host ""
Write-Host "已安装文件:" -ForegroundColor Cyan
Write-Host "  - $SkillsDir\SKILL.md"
Write-Host "  - $HooksDir\session-start.ps1"
Write-Host "  - $HooksDir\log-prompt.ps1"
Write-Host "  - $SettingsFile"
Write-Host ""
Write-Host "重启 Claude Code 后生效。" -ForegroundColor Yellow
