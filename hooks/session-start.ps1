# Claude Code 会话启动脚本 (Windows PowerShell)
# 设置会话创建日期，写入文件以便其他 hook 读取

# 生成会话日期时间戳
$SessionDate = Get-Date -Format "yyyyMMdd_HHmmss"

# 获取工作目录
$WorkDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { Get-Location }

# 将会话日期写入项目目录下的隐藏文件
$SessionFile = Join-Path $WorkDir ".claude_session_date"
$SessionDate | Out-File -FilePath $SessionFile -Encoding UTF8 -NoNewline

exit 0
