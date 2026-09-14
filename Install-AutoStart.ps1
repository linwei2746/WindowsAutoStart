# 「スタートアップ」フォルダにショートカットを作成し、ログイン時に AutoStart.ps1 を自動実行させる
# インストール:     powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1
# アンインストール: powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1 -Uninstall

param([switch]$Uninstall)

$script   = Join-Path $PSScriptRoot 'AutoStart.ps1'
$shortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoStart.lnk'

if ($Uninstall) {
    if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut }
    Write-Host "スタートアップ登録を削除しました: $shortcut"
    return
}

if (-not (Test-Path -LiteralPath $script)) { throw "見つかりません: $script" }

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
$lnk.TargetPath       = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$lnk.Arguments        = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$lnk.WorkingDirectory = $PSScriptRoot
$lnk.WindowStyle      = 7   # 最小化状態で実行し、黒い画面のちらつきを抑える
$lnk.Save()

Write-Host "スタートアップに登録しました: $shortcut"
