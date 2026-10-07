@echo off
set "JIS_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "JIS_PS=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%JIS_PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run.ps1" -Action RestoreSpaces
if errorlevel 1 echo FAILED. Read the error and the log before retrying.
pause