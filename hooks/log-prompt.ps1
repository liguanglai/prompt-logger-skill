# Claude Code 提示词记录脚本 (Windows PowerShell)
# 在记录用户输入前，先补记上一条 Claude 响应
# 支持对话编号功能

# 从 stdin 读取 JSON 输入
$inputData = [Console]::In.ReadToEnd()

# 解析 JSON
try {
    $data = $inputData | ConvertFrom-Json
} catch {
    exit 0
}

# 提取字段
$UserPrompt = $data.prompt
$SessionId = $data.session_id
$TranscriptPath = $data.transcript_path

# 如果没有 prompt，退出
if (-not $UserPrompt) {
    exit 0
}

# 使用 CLAUDE_PROJECT_DIR（Claude 启动目录）
$WorkDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }

# 获取会话日期
$SessionFile = Join-Path $WorkDir ".claude_session_date"
if (Test-Path $SessionFile) {
    $SessionDate = Get-Content $SessionFile -Raw
    $SessionDate = $SessionDate.Trim()
} else {
    $SessionDate = Get-Date -Format "yyyyMMdd_HHmmss"
}

$LogFile = Join-Path $WorkDir "claude_prompt-history-$SessionDate.md"
$CounterFile = Join-Path $WorkDir ".claude_msg_counter"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 获取当前消息编号
if (Test-Path $CounterFile) {
    $MsgNum = [int](Get-Content $CounterFile -Raw).Trim()
} else {
    $MsgNum = 0
}

# 如果文件不存在，创建带标题的文件
if (-not (Test-Path $LogFile)) {
    $DisplayDate = $SessionDate -replace '_', ' ' -replace '(\d{4})(\d{2})(\d{2})', '$1-$2-$3' -replace ' (\d{2})(\d{2})(\d{2})', ' $1:$2:$3'
    $Header = @"
# Claude Code 对话历史记录

**会话启动时间**: $DisplayDate
**工作目录**: $WorkDir

---

"@
    $Header | Out-File -FilePath $LogFile -Encoding UTF8
}

# === 补记上一条 Claude 响应 ===
if ($TranscriptPath -and (Test-Path $TranscriptPath)) {
    # 检查日志文件最后是否是用户输入（有 👤 用户 但没有对应的 🤖 Claude）
    $LastContent = Get-Content $LogFile -Tail 20 -ErrorAction SilentlyContinue
    $LastContentStr = $LastContent -join "`n"

    # 查找最后的用户和 Claude 标记
    $UserMatches = [regex]::Matches($LastContentStr, "👤 用户")
    $ClaudeMatches = [regex]::Matches($LastContentStr, "🤖 Claude")

    $HasUnmatchedUser = $false
    if ($UserMatches.Count -gt 0) {
        $LastUserIndex = $UserMatches[$UserMatches.Count - 1].Index
        if ($ClaudeMatches.Count -eq 0) {
            $HasUnmatchedUser = $true
        } else {
            $LastClaudeIndex = $ClaudeMatches[$ClaudeMatches.Count - 1].Index
            if ($LastUserIndex -gt $LastClaudeIndex) {
                $HasUnmatchedUser = $true
            }
        }
    }

    if ($HasUnmatchedUser) {
        # 从 JSONL 文件中提取最后一条有文本内容的 assistant 消息
        $Lines = Get-Content $TranscriptPath -Encoding UTF8
        [array]::Reverse($Lines)

        $LastResponse = $null
        foreach ($line in $Lines) {
            try {
                $entry = $line | ConvertFrom-Json
                if ($entry.type -eq "assistant" -and $entry.message.content) {
                    $content = $entry.message.content
                    if ($content -is [array]) {
                        $textParts = $content | Where-Object { $_.type -eq "text" } | ForEach-Object { $_.text }
                        if ($textParts) {
                            $LastResponse = $textParts -join "`n"
                            break
                        }
                    }
                }
            } catch {
                continue
            }
        }

        if ($LastResponse) {
            $ResponseBlock = @"

### 🤖 Claude #$MsgNum ($Timestamp)

$LastResponse

---

"@
            $ResponseBlock | Out-File -FilePath $LogFile -Encoding UTF8 -Append
        }
    }
}

# === 递增编号并记录当前用户提示词 ===
$MsgNum = $MsgNum + 1
$MsgNum | Out-File -FilePath $CounterFile -Encoding UTF8 -NoNewline

$PromptBlock = @"

### 👤 用户 #$MsgNum ($Timestamp)

$UserPrompt

"@
$PromptBlock | Out-File -FilePath $LogFile -Encoding UTF8 -Append

exit 0
