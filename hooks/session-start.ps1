# Claude Code Session Start Script (Windows PowerShell)

# Set UTF-8 encoding for stdin/stdout
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Generate session date timestamp
$SessionDate = Get-Date -Format "yyyyMMdd_HHmmss"

# Read JSON input from stdin to get working directory
$input_text = [Console]::In.ReadToEnd()
$WorkDir = $null

try {
    $json = $input_text | ConvertFrom-Json
    if ($json.cwd) {
        $WorkDir = $json.cwd
    }
} catch {}

# Fallback to USERPROFILE if no cwd
if ([string]::IsNullOrEmpty($WorkDir)) {
    $WorkDir = $env:USERPROFILE
}

# Write session date to hidden file in project directory
$SessionFile = Join-Path $WorkDir ".claude_session_date"
$SessionDate | Out-File -FilePath $SessionFile -Encoding UTF8 -NoNewline

# Set file as hidden
if (Test-Path $SessionFile) {
    $file = Get-Item $SessionFile -Force
    $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden
}

exit 0
