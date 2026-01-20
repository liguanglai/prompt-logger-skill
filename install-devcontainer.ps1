# Prompt Logger Skill - DevContainer 安装脚本 (Windows PowerShell)
# 用于在现有 DevContainer 项目中添加 Prompt Logger Skill
#
# 使用方法:
#   # 下载脚本
#   Invoke-WebRequest -Uri "https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
#   # 运行
#   .\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"

param(
    [Parameter(Position=0)]
    [string]$ProjectDir = "."
)

# 颜色输出函数
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red; exit 1 }

# 解析完整路径
$ProjectDir = (Resolve-Path $ProjectDir).Path
Write-Info "安装 Prompt Logger Skill 到 DevContainer 项目: $ProjectDir"

# 检查必要文件
$DevcontainerDir = Join-Path $ProjectDir ".devcontainer"
$ClaudeDir = Join-Path $ProjectDir ".claude"

if (-not (Test-Path $DevcontainerDir)) {
    Write-Err "未找到 .devcontainer 目录: $DevcontainerDir"
}

$DockerfilePath = Join-Path $DevcontainerDir "Dockerfile"
$DevcontainerJsonPath = Join-Path $DevcontainerDir "devcontainer.json"

if (-not (Test-Path $DockerfilePath)) {
    Write-Err "未找到 Dockerfile: $DockerfilePath"
}

if (-not (Test-Path $DevcontainerJsonPath)) {
    Write-Err "未找到 devcontainer.json: $DevcontainerJsonPath"
}

# 创建 .claude 目录
if (-not (Test-Path $ClaudeDir)) {
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

# 备份原文件
Write-Info "备份原文件..."
Copy-Item $DockerfilePath "$DockerfilePath.bak" -Force
Copy-Item $DevcontainerJsonPath "$DevcontainerJsonPath.bak" -Force
$SettingsPath = Join-Path $ClaudeDir "settings.json"
if (Test-Path $SettingsPath) {
    Copy-Item $SettingsPath "$SettingsPath.bak" -Force
}

# ============================================
# 1. 修改 Dockerfile
# ============================================
Write-Info "修改 Dockerfile..."

$DockerfileContent = Get-Content $DockerfilePath -Raw

if ($DockerfileContent -match "Prompt Logger Skill") {
    Write-Warn "Dockerfile 中已包含 Prompt Logger Skill 安装，跳过"
} else {
    # 检测用户名
    if ($DockerfileContent -match "USER vscode") {
        $ContainerUser = "vscode"
        $ClaudeHome = "/home/vscode/.claude"
    } else {
        $ContainerUser = "root"
        $ClaudeHome = "/root/.claude"
    }

    Write-Info "检测到容器用户: $ContainerUser"

    $InstallBlock = @"

# ==== Prompt Logger Skill インストール ====
USER $ContainerUser
RUN curl -LO https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/prompt-logger-macos.tar.gz \
    && tar -xzf prompt-logger-macos.tar.gz \
    && cd prompt-logger-skill-package \
    && mkdir -p $ClaudeHome/hooks $ClaudeHome/skills/prompt-logger \
    && cp hooks/*.sh $ClaudeHome/hooks/ \
    && cp skills/prompt-logger/SKILL.md $ClaudeHome/skills/prompt-logger/ \
    && chmod +x $ClaudeHome/hooks/*.sh \
    && cd .. \
    && rm -rf prompt-logger-skill-package prompt-logger-macos.tar.gz
"@

    # 追加到 Dockerfile 末尾
    Add-Content -Path $DockerfilePath -Value $InstallBlock
    Write-Info "Dockerfile 已更新"
}

# ============================================
# 2. 修改 devcontainer.json
# ============================================
Write-Info "修改 devcontainer.json..."

$DevcontainerContent = Get-Content $DevcontainerJsonPath -Raw

if ($DevcontainerContent -match "CLAUDE_PROJECT_DIR") {
    Write-Warn "devcontainer.json 中已包含 CLAUDE_PROJECT_DIR，跳过"
} else {
    try {
        $DevcontainerJson = $DevcontainerContent | ConvertFrom-Json

        # 添加 containerEnv
        if (-not $DevcontainerJson.containerEnv) {
            $DevcontainerJson | Add-Member -NotePropertyName "containerEnv" -NotePropertyValue @{} -Force
        }
        $DevcontainerJson.containerEnv | Add-Member -NotePropertyName "CLAUDE_PROJECT_DIR" -NotePropertyValue '${containerWorkspaceFolder}' -Force

        # 保存（格式化输出）
        $DevcontainerJson | ConvertTo-Json -Depth 10 | Set-Content $DevcontainerJsonPath -Encoding UTF8
        Write-Info "devcontainer.json 已更新"
    } catch {
        Write-Warn "无法解析 devcontainer.json，请手动添加 containerEnv"
        Write-Host @"
请在 devcontainer.json 中添加:
  "containerEnv": {
    "CLAUDE_PROJECT_DIR": "`${containerWorkspaceFolder}"
  },
"@
    }
}

# ============================================
# 3. 修改/创建 .claude/settings.json
# ============================================
Write-Info "配置 .claude/settings.json..."

# 检测用户名
$DockerfileContent = Get-Content $DockerfilePath -Raw
if ($DockerfileContent -match "USER vscode") {
    $ClaudeHome = "/home/vscode/.claude"
} else {
    $ClaudeHome = "/root/.claude"
}

$HooksConfig = @{
    hooks = @{
        SessionStart = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "$ClaudeHome/hooks/session-start.sh"
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
                        command = "$ClaudeHome/hooks/log-prompt.sh"
                    }
                )
            }
        )
        Stop = @(
            @{
                matcher = ""
                hooks = @(
                    @{
                        type = "command"
                        command = "$ClaudeHome/hooks/log-response.sh"
                    }
                )
            }
        )
    }
}

if (Test-Path $SettingsPath) {
    $SettingsContent = Get-Content $SettingsPath -Raw

    if ($SettingsContent -match '"hooks"') {
        Write-Warn "settings.json 中已包含 hooks 配置，跳过"
    } else {
        try {
            $SettingsJson = $SettingsContent | ConvertFrom-Json

            # 合并 hooks
            $SettingsJson | Add-Member -NotePropertyName "hooks" -NotePropertyValue $HooksConfig.hooks -Force

            $SettingsJson | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
            Write-Info "settings.json 已合并 hooks 配置"
        } catch {
            Write-Warn "无法解析 settings.json，请手动添加 hooks 配置"
        }
    }
} else {
    # 创建新的 settings.json
    $HooksConfig | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
    Write-Info "已创建 settings.json"
}

# ============================================
# 完成
# ============================================
Write-Host ""
Write-Info "=========================================="
Write-Info "Prompt Logger Skill 安装完成！"
Write-Info "=========================================="
Write-Host ""
Write-Info "下一步:"
Write-Info "  1. 在 VS Code 中按 F1"
Write-Info "  2. 选择 'Dev Containers: Rebuild Container'"
Write-Info "  3. 容器重建后，Claude Code 对话将自动记录到工作目录"
Write-Host ""
Write-Info "备份文件位置:"
Write-Info "  - $DockerfilePath.bak"
Write-Info "  - $DevcontainerJsonPath.bak"
if (Test-Path "$SettingsPath.bak") {
    Write-Info "  - $SettingsPath.bak"
}
Write-Host ""
