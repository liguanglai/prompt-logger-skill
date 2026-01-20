# Claude Code Prompt Logger (Windows PowerShell)
# Records user prompts and backfills Claude responses
# Supports conversation numbering

# Read JSON input from stdin
# Claude Code passes: {"session_id":"...", "transcript_path":"...", "cwd":"...", "prompt":"...", ...}
$inputData = [Console]::In.ReadToEnd()

# Parse JSON
try {
    $data = $inputData | ConvertFrom-Json
} catch {
    exit 0
}

# Extract fields
$UserPrompt = $data.prompt
$SessionId = $data.session_id
$TranscriptPath = $data.transcript_path
$WorkDir = $data.cwd

# Exit if no prompt
if (-not $UserPrompt) {
    exit 0
}

# Fallback methods if cwd not in JSON
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

# Final fallback to USERPROFILE
if ([string]::IsNullOrEmpty($WorkDir)) {
    $WorkDir = $env:USERPROFILE
}

# Get session date
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

# Get current message number
if (Test-Path $CounterFile) {
    $MsgNum = [int](Get-Content $CounterFile -Raw).Trim()
} else {
    $MsgNum = 0
}

# Code fence marker
$CodeFence = '```'

# Create file with header if it does not exist
if (-not (Test-Path $LogFile)) {
    $DisplayDate = $SessionDate -replace '_', ' ' -replace '(\d{4})(\d{2})(\d{2})', '$1-$2-$3' -replace ' (\d{2})(\d{2})(\d{2})', ' $1:$2:$3'
    $Header = "# Claude Code Conversation History`r`n`r`n"
    $Header += "**Session Start**: $DisplayDate`r`n"
    $Header += "**Working Directory**: $WorkDir`r`n`r`n"
    $Header += "---`r`n"
    $Header | Out-File -FilePath $LogFile -Encoding UTF8
}

# === Backfill previous Claude response ===
if ($TranscriptPath -and (Test-Path $TranscriptPath)) {
    # Check if last entry in log is user input without Claude response
    $LastContent = Get-Content $LogFile -Tail 20 -ErrorAction SilentlyContinue
    $LastContentStr = $LastContent -join "`n"

    # Find last user and Claude markers
    $UserMatches = [regex]::Matches($LastContentStr, "User #\d+")
    $ClaudeMatches = [regex]::Matches($LastContentStr, "Claude #\d+")

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
        # Extract last assistant message with text content from JSONL
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
            $ResponseBlock = "`r`n### Claude #$MsgNum ($Timestamp)`r`n`r`n$LastResponse`r`n`r`n---`r`n"
            $ResponseBlock | Out-File -FilePath $LogFile -Encoding UTF8 -Append
        }
    }
}

# === Increment counter and record current user prompt ===
$MsgNum = $MsgNum + 1
$MsgNum | Out-File -FilePath $CounterFile -Encoding UTF8 -NoNewline

$PromptBlock = "`r`n### User #$MsgNum ($Timestamp)`r`n`r`n$UserPrompt`r`n"
$PromptBlock | Out-File -FilePath $LogFile -Encoding UTF8 -Append

exit 0
