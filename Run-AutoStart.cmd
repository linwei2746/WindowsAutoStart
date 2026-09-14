@echo off
rem ============================================================
rem  AutoStart.ps1 launcher for machines where PowerShell script
rem  execution is disabled (Restricted / RemoteSigned / GPO).
rem
rem  The execution policy only blocks loading a .ps1 FILE. A command
rem  passed with -Command is not blocked, so we read the script text
rem  and run it with Invoke-Expression instead of using -File.
rem ============================================================
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -WindowStyle Hidden -Command "Invoke-Expression (Get-Content -LiteralPath 'AutoStart.ps1' -Raw -Encoding UTF8)"
endlocal
