@echo off
set "JIS_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "JIS_PS=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%JIS_PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-Installed.ps1"
pause