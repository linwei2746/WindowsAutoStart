@echo off
rem ============================================================
rem  Installs / removes the startup entry on machines where
rem  PowerShell script execution is disabled, by reading
rem  Install-AutoStart.ps1 and running it with Invoke-Expression
rem  (which the execution policy does not block).
rem
rem  Add:     Install-AutoStart.cmd
rem  Remove:  Install-AutoStart.cmd -Uninstall
rem ============================================================
setlocal
cd /d "%~dp0"
set "MODE="
if /I "%~1"=="-Uninstall" set "MODE=-Uninstall"
if /I "%~1"=="/Uninstall" set "MODE=-Uninstall"
powershell.exe -NoProfile -Command "$env:AUTOSTART_UNINSTALL='%MODE%'; Invoke-Expression (Get-Content -LiteralPath 'Install-AutoStart.ps1' -Raw -Encoding UTF8)"
endlocal
