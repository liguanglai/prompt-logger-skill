# Claude Code Session Start Script (Windows PowerShell)
# Sets session creation date and writes to file for other hooks to read

# Generate session date timestamp
$SessionDate = Get-Date -Format "yyyyMMdd_HHmmss"

# Read JSON input from stdin to get working directory
# Claude Code passes: {"session_id":"...", "cwd":"...", ...}
$input_text = [Console]::In.ReadToEnd()
$WorkDir = $null

try {
    $json = $input_text | ConvertFrom-Json
    if ($json.cwd) {
        $WorkDir = $json.cwd
    }
} catch {}

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

# Write session date to hidden file in project directory
$SessionFile = Join-Path $WorkDir ".claude_session_date"
$SessionDate | Out-File -FilePath $SessionFile -Encoding UTF8 -NoNewline

# Set file as hidden (Windows)
if (Test-Path $SessionFile) {
    try {
        $file = Get-Item $SessionFile -Force
        $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden
    } catch {}
}

exit 0
