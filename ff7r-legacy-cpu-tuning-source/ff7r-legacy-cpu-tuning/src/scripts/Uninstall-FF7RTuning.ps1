<#
.SYNOPSIS
  FF7R Legacy CPU Tuning - uninstaller.

.DESCRIPTION
  - Restores your original Engine.ini from the backup the installer made,
    or removes the tuned one if you had none before.
  - Deletes the "FF7R Legacy CPU Tuning" power plan (switching back to
    Balanced first if it happens to be active).
  Does not touch FFVIIHook or any other mod.
#>

$ErrorActionPreference = 'Continue'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

$Marker   = 'FF7R Legacy CPU Tuning'
$PlanGuid = 'f7f7f7f7-7777-4777-8777-1462040f7f7f'

Write-Host ""
Write-Host "=== $Marker - uninstaller ===" -ForegroundColor Cyan
Write-Host ""

# Engine.ini. Note: when elevated, MyDocuments is the elevated user's folder,
# which is the same person in normal (non "Run as different user") setups.
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

Write-Host ""
Write-Host "Uninstall complete. You can delete this mod's folder now." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
