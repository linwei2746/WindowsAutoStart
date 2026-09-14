# 「スタートアップ」フォルダにショートカットを作成し、ログイン時に自動実行させる。
# 作成されるショートカットは Run-AutoStart.cmd を指す（スクリプト実行が禁止された環境でも動く方式）。
#
# 通常の環境:
#   インストール:     powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1
#   アンインストール: powershell -ExecutionPolicy Bypass -File Install-AutoStart.ps1 -Uninstall
# スクリプト実行が禁止された環境:
#   インストール:     Install-AutoStart.cmd
#   アンインストール: Install-AutoStart.cmd -Uninstall

param([switch]$Uninstall)

# 実行フォルダ。.cmd 経由（Invoke-Expression）だと $PSScriptRoot が空になるため、
# その場合は作業フォルダ（.cmd が cd 済み）で補う。
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# .cmd 経由では param のバインドが効かないので、環境変数でもアンインストールを判定する。
$doUninstall = $Uninstall -or ($env:AUTOSTART_UNINSTALL -eq '-Uninstall')

$launcher = Join-Path $ScriptDir 'Run-AutoStart.cmd'
$shortcut = Join-Path ([Environment]::GetFolderPath('Startup')) 'AutoStart.lnk'

if ($doUninstall) {
    if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut }
    Write-Host "スタートアップ登録を削除しました: $shortcut"
    return
}

if (-not (Test-Path -LiteralPath $launcher)) { throw "見つかりません: $launcher" }

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
$lnk.TargetPath       = $launcher
$lnk.WorkingDirectory = $ScriptDir
$lnk.WindowStyle      = 7   # 最小化状態で実行し、黒い画面のちらつきを抑える
$lnk.Save()

Write-Host "スタートアップに登録しました: $shortcut"
Write-Host "  -> $launcher"
