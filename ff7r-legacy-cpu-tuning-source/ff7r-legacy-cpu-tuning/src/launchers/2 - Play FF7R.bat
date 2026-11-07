@echo off
rem FF7R Legacy CPU Tuning - starts the game with CPU and audio tuning.
rem Epic users: add -NoLaunch, then start the game yourself.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\FF7R-Launcher.ps1" %*
