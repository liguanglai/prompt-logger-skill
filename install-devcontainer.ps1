# Prompt Logger Skill - DevContainer 安装脚本 (Windows PowerShell)
# 在宿主机运行，自动配置 devcontainer.json
#
# 使用方法:
#   Invoke-WebRequest -Uri "https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-devcontainer.ps1" -OutFile "install-devcontainer.ps1"
#   .\install-devcontainer.ps1 -ProjectDir "C:\path\to\your\devcontainer\project"

param(
    [Parameter(Position=0)]
    [string]$ProjectDir = "."
)

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Err { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red; exit 1 }

# 解析完整路径
$ProjectDir = (Resolve-Path $ProjectDir).Path
Write-Info "配置 Prompt Logger Skill: $ProjectDir"

# 检查 devcontainer.json
$DevcontainerJson = Join-Path $ProjectDir ".devcontainer\devcontainer.json"

if (-not (Test-Path $DevcontainerJson)) {
    Write-Err "未找到 devcontainer.json: $DevcontainerJson"
}

# 备份
Write-Info "备份 devcontainer.json..."
Copy-Item $DevcontainerJson "$DevcontainerJson.bak" -Force

# 读取现有配置
$Content = Get-Content $DevcontainerJson -Raw

# 检查是否已配置
if ($Content -match "install-in-container.sh") {
    Write-Warn "已配置 Prompt Logger Skill，跳过"
    exit 0
}

Write-Info "更新 devcontainer.json..."

try {
    $Json = $Content | ConvertFrom-Json

    $InstallCmd = "curl -fsSL https://github.com/liguanglai/prompt-logger-skill/releases/latest/download/install-in-container.sh | bash"

    # 处理 postCreateCommand
    if ($Json.postCreateCommand) {
        $Json.postCreateCommand = "$($Json.postCreateCommand) && $InstallCmd"
    } else {
        $Json | Add-Member -NotePropertyName "postCreateCommand" -NotePropertyValue $InstallCmd -Force
    }

    # 处理 containerEnv
    if (-not $Json.containerEnv) {
        $Json | Add-Member -NotePropertyName "containerEnv" -NotePropertyValue @{} -Force
    }
    $Json.containerEnv | Add-Member -NotePropertyName "CLAUDE_PROJECT_DIR" -NotePropertyValue '${containerWorkspaceFolder}' -Force

    # 保存
    $Json | ConvertTo-Json -Depth 10 | Set-Content $DevcontainerJson -Encoding UTF8

    Write-Info "=========================================="
    Write-Info "配置完成！"
    Write-Info "=========================================="
    Write-Host ""
    Write-Info "已添加到 devcontainer.json:"
    Write-Host "  - postCreateCommand: 容器创建后自动安装"
    Write-Host "  - containerEnv.CLAUDE_PROJECT_DIR: 日志输出目录"
    Write-Host ""
    Write-Info "下一步:"
    Write-Info "  1. VS Code 中按 F1"
    Write-Info "  2. 选择 'Dev Containers: Rebuild Container'"
    Write-Host ""
    Write-Info "备份文件: $DevcontainerJson.bak"

} catch {
    Write-Err "无法解析 devcontainer.json: $_"
}
