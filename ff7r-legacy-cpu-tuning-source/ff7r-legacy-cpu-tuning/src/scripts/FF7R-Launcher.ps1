<#
.SYNOPSIS
  FF7R Legacy CPU Tuning - launcher.

.DESCRIPTION
  While Final Fantasy VII Remake Intergrade runs (everything reverts on exit):
    1. Switches to a dedicated power plan:
         - CPU minimum state 100%: no clock ramping mid-scene (a common cause
           of hitches and audio dropouts on FX-era CPUs)
         - Core parking off: all cores stay awake
         - PCIe link power saving off
         - USB selective suspend off (USB headset / DAC crackle)
    2. Launches the game through Steam with -USEALLAVAILABLECORES.
    3. Raises the game to Above Normal priority.
    4. Raises Windows' audio engine (audiodg.exe) to High priority, and
       re-applies it if Windows restarts the audio engine.
    5. On exit, restores the previous power plan and priorities.

  Epic users: start the game yourself after this window says it's waiting;
  the launcher tunes it the same way.

  Needs admin (power plan + audio engine priority). Asks once per launch.
#>
param(
    [switch]$NoLaunch   # don't start the game, just wait for it (Epic users)
)

$ErrorActionPreference = 'Continue'

# --- Self-elevate --------------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($NoLaunch) { $argList += ' -NoLaunch' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

# --- Settings ------------------------------------------------------------
$AppId       = 1462040
$GameProcess = 'ff7remake_'
$LaunchArgs  = '-USEALLAVAILABLECORES'
$PlanGuid    = 'f7f7f7f7-7777-4777-8777-1462040f7f7f'
$PlanName    = 'FF7R Legacy CPU Tuning'
$GuidRegex   = '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}'

function Log($msg, $color = 'Gray') {
    Write-Host ("[FF7R {0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg) -ForegroundColor $color
}

function Set-AudioPriority([string]$level) {
    $a = Get-Process -Name audiodg -ErrorAction SilentlyContinue
    if ($a) {
        try { $a.PriorityClass = $level; return $a.Id }
        catch { Log "Couldn't set audio engine priority ($($_.Exception.Message))." 'Yellow' }
    }
    return $null
}

$host.UI.RawUI.WindowTitle = 'FF7R Legacy CPU Tuning - leave this open while you play'

# --- Sanity check: is the Engine.ini installed? --------------------------
$docs = [Environment]::GetFolderPath('MyDocuments')
$ini  = Join-Path $docs 'My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\Engine.ini'
if (-not (Test-Path $ini) -or -not (Select-String -Path $ini -Pattern 'FF7R Legacy CPU Tuning' -Quiet)) {
    Log "Tuned Engine.ini not found. Run '1 - Install (run once).bat' first for the full effect." 'Yellow'
}

# --- 1. Power plan -------------------------------------------------------
$originalPlan = [regex]::Match((powercfg /getactivescheme | Out-String), $GuidRegex).Value
Log "Current power plan saved: $originalPlan"

if (-not ((powercfg /list | Out-String) -match $PlanGuid)) {
    powercfg /duplicatescheme SCHEME_MIN $PlanGuid | Out-Null
    if ($LASTEXITCODE -ne 0) { powercfg /duplicatescheme SCHEME_BALANCED $PlanGuid | Out-Null }
    powercfg /changename $PlanGuid $PlanName 'Used by FF7R Legacy CPU Tuning while the game runs' | Out-Null
    Log "Created power plan '$PlanName'."
}

powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR CPMINCORES 100      | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PCIEXPRESS ASPM 0             | Out-Null
powercfg /setacvalueindex $PlanGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
powercfg /setactive $PlanGuid | Out-Null
Log "Performance power plan active (full clock, all cores awake)." 'Green'

try {
    # --- 2. Launch ---------------------------------------------------------
    if (-not $NoLaunch) {
        $steamExe = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamExe
        if (-not $steamExe -or -not (Test-Path $steamExe)) { $steamExe = "${env:ProgramFiles(x86)}\Steam\steam.exe" }
        if (Test-Path $steamExe) {
            Start-Process -FilePath $steamExe -ArgumentList "-applaunch $AppId $LaunchArgs"
            Log "Launching through Steam with $LaunchArgs ..."
        } else {
            Log "Steam not found. Start the game yourself now; it will still be tuned." 'Yellow'
        }
    } else {
        Log "Waiting for you to start the game ..."
    }

    # --- 3. Wait for the game (up to 5 minutes) ----------------------------
    $game = $null
    $deadline = (Get-Date).AddMinutes(5)
    while (-not $game -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        $game = Get-Process -Name $GameProcess -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if (-not $game) { Log "Game didn't start within 5 minutes. Restoring settings." 'Yellow'; return }

    Start-Sleep -Seconds 5
    try { $game.PriorityClass = 'AboveNormal'; Log "Game priority: Above Normal." }
    catch { Log "Couldn't raise game priority ($($_.Exception.Message))." 'Yellow' }

    $audioPid = Set-AudioPriority 'High'
    if ($audioPid) { Log "Windows audio engine priority: High." }

    Log "All set. Settings revert automatically when the game closes." 'Green'

    # --- 4. Watch until exit ----------------------------------------------
    while (Get-Process -Id $game.Id -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 15
        $current = Get-Process -Name audiodg -ErrorAction SilentlyContinue
        if ($current -and $current.Id -ne $audioPid) {
            $audioPid = Set-AudioPriority 'High'
            Log "Audio engine restarted by Windows; priority re-applied."
        }
    }
    Log "Game closed."
}
finally {
    # --- 5. Restore --------------------------------------------------------
    Set-AudioPriority 'Normal' | Out-Null
    if ($originalPlan) { powercfg /setactive $originalPlan | Out-Null }
    Log "Restored your normal power plan and audio priority." 'Green'
    Start-Sleep -Seconds 3
}
