# 在“启动”文件夹里创建快捷方式，让 AutoStart.ps1 在登录后自动运行
# 安装:  powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1
# 卸载:  powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1 -Uninstall

param([switch]$Uninstall)

$script   = Join-Path $PSScriptRoot 'AutoStart.ps1'
$shortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoStart.lnk'

if ($Uninstall) {
    if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut }
    Write-Host "已移除开机启动: $shortcut"
    return
}

if (-not (Test-Path -LiteralPath $script)) { throw "找不到 $script" }

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
$lnk.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.WindowStyle      = 7   # 最小化运行，减少黑框闪烁
$lnk.Save()

Write-Host "已添加开机启动: $shortcut"
