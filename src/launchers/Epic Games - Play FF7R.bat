@echo off
rem Smooth Midgar - Epic Games Store only. Steam users just press Play in Steam.
rem Approve the admin prompt, start the game from Epic, and keep the window open while you play.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0files\FF7R-Launcher.ps1" -NoLaunch
