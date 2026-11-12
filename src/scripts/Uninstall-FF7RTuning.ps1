<#
.SYNOPSIS
  Smooth Midgar (FF7R Legacy CPU Tuning) - uninstaller.

.DESCRIPTION
  - Restores your original Engine.ini from the backup the installer made,
    or removes the tuned one if you had none before.
  - Deletes the "FF7R Legacy CPU Tuning" power plan (switching back to
    Balanced first if it happens to be active).
  - Removes the launcher from the game's Steam launch options (keeping your
    own options) and deletes %LOCALAPPDATA%\SmoothMidgar.
  Does not need admin rights.
  Does not touch FFVIIHook or any other mod.
#>

$ErrorActionPreference = 'Continue'

$Marker   = 'FF7R Legacy CPU Tuning'
$PlanGuid = 'f7f7f7f7-7777-4777-8777-1462040f7f7f'

Write-Host ""
Write-Host "=== $Marker - uninstaller ===" -ForegroundColor Cyan
Write-Host ""

if (Get-Process -Name ff7remake_ -ErrorAction SilentlyContinue) {
    Write-Host "Close the game first, then run this again." -ForegroundColor Yellow
    Read-Host "Press Enter to close"; exit 1
}

# Engine.ini
$docs   = [Environment]::GetFolderPath('MyDocuments')
$ini    = Join-Path $docs 'My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\Engine.ini'
$backup = "$ini.pre-legacytuning.bak"

if (Test-Path $backup) {
    Move-Item $backup $ini -Force
    Write-Host "Restored your original Engine.ini." -ForegroundColor Green
} elseif ((Test-Path $ini) -and (Select-String -Path $ini -Pattern $Marker -SimpleMatch -Quiet)) {
    Remove-Item $ini -Force
    Write-Host "Removed the tuned Engine.ini (you had none before)." -ForegroundColor Green
} else {
    Write-Host "No tuned Engine.ini found; left your config alone."
}

# Power plan
if ((powercfg /list | Out-String) -match $PlanGuid) {
    if ((powercfg /getactivescheme | Out-String) -match $PlanGuid) {
        powercfg /setactive SCHEME_BALANCED | Out-Null
    }
    powercfg /delete $PlanGuid | Out-Null
    Write-Host "Removed the '$Marker' power plan." -ForegroundColor Green
}

# Steam launch option + launcher
. (Join-Path $PSScriptRoot 'SteamLaunchOptions.ps1')
$steam = Get-SteamInfo
if ($steam -and $steam.Configs) {
    $needed = $false
    foreach ($c in $steam.Configs) {
        if ((Get-Content -LiteralPath $c.FullName -Raw) -match 'FF7R-Launcher\.ps1') { $needed = $true }
    }
    if ($needed) {
        try {
            $restart = Stop-SteamForEdit $steam
            foreach ($c in $steam.Configs) { Update-LaunchOptions $c.FullName 'remove' | Out-Null }
            Write-Host "Removed Smooth Midgar from the game's Steam launch options (your own options were kept)." -ForegroundColor Green
            if ($restart) { Start-Process $steam.Exe -ArgumentList '-silent'; Write-Host "Steam restarted." }
        } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
    }
}
if (Test-Path $LauncherDir) {
    Remove-Item $LauncherDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed $LauncherDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "Uninstall complete. You can delete this mod's folder now." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
