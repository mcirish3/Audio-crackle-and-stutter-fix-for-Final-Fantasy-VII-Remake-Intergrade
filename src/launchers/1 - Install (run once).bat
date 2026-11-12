@echo off
rem Smooth Midgar - detects your hardware, installs a tuned Engine.ini and sets up the Steam Play button.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\Install-FF7RTuning.ps1" %*
pause
