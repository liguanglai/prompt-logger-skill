# Claude Code Prompt Logger (Windows PowerShell)

# Set UTF-8 encoding for stdin/stdout
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Read JSON input from stdin
$input_text = [Console]::In.ReadToEnd()

# Parse JSON
$json = $null
$UserPrompt = $null
$WorkDir = $null

try {
    $json = $input_text | ConvertFrom-Json
    $UserPrompt = $json.prompt
    $WorkDir = $json.cwd
} catch {
    exit 0
}

# Exit if no prompt content
if ([string]::IsNullOrEmpty($UserPrompt)) {
    exit 0
}

# Fallback to USERPROFILE if no cwd in JSON
if ([string]::IsNullOrEmpty($WorkDir)) {
    $WorkDir = $env:USERPROFILE
}

# Get session start date
$SessionFile = Join-Path $WorkDir ".claude_session_date"
if (Test-Path $SessionFile) {
    $SessionDate = Get-Content $SessionFile -Raw
    $SessionDate = $SessionDate.Trim()
} else {
    $SessionDate = Get-Date -Format "yyyyMMdd_HHmmss"
}

# Log file path
$LogFile = Join-Path $WorkDir "claude_prompt-history-$SessionDate.md"

# Current timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Code fence marker
$CodeFence = '```'

# Create file with header if it does not exist
if (-not (Test-Path $LogFile)) {
    $DisplayDate = $SessionDate -replace '_', ' '
    $DisplayDate = $DisplayDate -replace '(\d{4})(\d{2})(\d{2})', '$1-$2-$3'
    $DisplayDate = $DisplayDate -replace ' (\d{2})(\d{2})(\d{2})', ' $1:$2:$3'

    $Header = "# Claude Code Test Log`r`n`r`n"
    $Header += "---`r`n"
    $Header | Out-File -FilePath $LogFile -Encoding UTF8
}

# Append new prompt entry
$Entry = "`r`n## $Timestamp`r`n`r`n"
$Entry += "$CodeFence`r`n"
$Entry += "$UserPrompt`r`n"
$Entry += "$CodeFence`r`n"

$Entry | Out-File -FilePath $LogFile -Encoding UTF8 -Append

exit 0
