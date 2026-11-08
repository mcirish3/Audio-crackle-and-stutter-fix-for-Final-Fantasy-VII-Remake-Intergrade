@echo off
rem FF7R Legacy CPU Tuning - detects your hardware and installs a tuned Engine.ini.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\Install-FF7RTuning.ps1" %*
pause
