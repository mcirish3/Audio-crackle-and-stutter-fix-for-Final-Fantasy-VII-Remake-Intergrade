<#
.SYNOPSIS
  Smooth Midgar (FF7R Legacy CPU Tuning) - launcher.

.DESCRIPTION
  While Final Fantasy VII Remake Intergrade runs (everything reverts on exit):
    1. Switches to a dedicated power plan:
         - CPU minimum state 100%: no clock ramping mid-scene (a common cause
           of hitches and audio dropouts on FX-era CPUs)
         - Core parking off: all cores stay awake
         - PCIe link power saving off
         - USB selective suspend off (USB headset / DAC crackle)
    2. Starts the game with -USEALLAVAILABLECORES.
    3. Raises the game to Above Normal priority.
    4. If running as admin: raises Windows' audio engine (audiodg.exe) to
       High priority, and re-applies it if Windows restarts the audio engine.
    5. On exit, restores the previous power plan and priorities.

  Steam (normal use): the installer sets the game's Steam launch options to
    "<powershell.exe>" ... -File "<this script>" %command%
  so pressing Play in Steam runs this hidden, with Steam's game command as
  the arguments. No admin prompt. A log is written to
    %LOCALAPPDATA%\SmoothMidgar\launcher.log

  Epic: run with -NoLaunch, then start the game from Epic. This mode asks for
  admin once so it can also raise the audio engine priority.

  This script has no param() block on purpose: in Steam mode every argument
  belongs to the game, and PowerShell must not try to bind any of them.
#>

$ErrorActionPreference = 'Continue'

$GameProcess = 'ff7remake_'
$LaunchArgs  = '-USEALLAVAILABLECORES'
$PlanGuid    = 'f7f7f7f7-7777-4777-8777-1462040f7f7f'
$PlanName    = 'FF7R Legacy CPU Tuning'
$GuidRegex   = '[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}'
$StateDir    = Join-Path $env:LOCALAPPDATA 'SmoothMidgar'
$StateFile   = Join-Path $StateDir 'previous-power-plan.txt'
$LogFile     = Join-Path $StateDir 'launcher.log'

$gameCommand = @($args)
$epicMode = ($gameCommand.Count -ge 1 -and $gameCommand[0] -eq '-NoLaunch')
$steamMode = ($gameCommand.Count -ge 1 -and -not $epicMode)

$isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Epic mode asks for admin once (audio engine priority). Steam mode never does:
# a UAC prompt on every Play press would be worse than skipping that one tweak.
if ($epicMode -and -not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -NoLaunch"
    exit
}

New-Item -ItemType Directory -Path $StateDir -Force | Out-Null
if ($steamMode) { Set-Content -Path $LogFile -Value '' -Encoding ASCII }

function Log($msg, $color = 'Gray') {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    if ($steamMode) { Add-Content -Path $LogFile -Value $line -Encoding ASCII }
    else { Write-Host "[FF7R] $line" -ForegroundColor $color }
}

if (-not $steamMode -and -not $epicMode) {
    Write-Host ''
    Write-Host 'Smooth Midgar now runs from the Steam Play button.' -ForegroundColor Cyan
    Write-Host 'Run "1 - Install (run once).bat" once, then just press Play in Steam.'
    Write-Host 'Epic Games users: use "Epic Games - Play FF7R.bat" instead.'
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
    exit
}

function Set-AudioPriority([string]$level) {
    if (-not $isAdmin) { return $null }
    $a = Get-Process -Name audiodg -ErrorAction SilentlyContinue
    if ($a) {
        try { $a.PriorityClass = $level; return $a.Id }
        catch { Log "Couldn't set audio engine priority ($($_.Exception.Message))." 'Yellow' }
    }
    return $null
}

function Join-CommandArgs([string[]]$list) {
    ($list | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
}

if (-not $steamMode) { $host.UI.RawUI.WindowTitle = 'Smooth Midgar - leave this open while you play' }
Log "Smooth Midgar launcher ($(if ($steamMode) { 'Steam' } else { 'Epic' }) mode, admin: $isAdmin)"

# --- Sanity check: is the Engine.ini installed? --------------------------
$docs = [Environment]::GetFolderPath('MyDocuments')
$ini  = Join-Path $docs 'My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\Engine.ini'
if (-not (Test-Path $ini) -or -not (Select-String -Path $ini -Pattern 'FF7R Legacy CPU Tuning' -SimpleMatch -Quiet)) {
    Log "Tuned Engine.ini not found. Run '1 - Install (run once).bat' for the full effect." 'Yellow'
}

# --- 1. Power plan -------------------------------------------------------
# If our plan is already active, a previous session didn't get to restore
# (crash, power cut): use the plan saved then, not ours.
$activePlan = [regex]::Match((powercfg /getactivescheme | Out-String), $GuidRegex).Value
if ($activePlan -ieq $PlanGuid) {
    $saved = if (Test-Path $StateFile) { (Get-Content $StateFile -Raw).Trim() } else { '' }
    $originalPlan = if ($saved -match "^$GuidRegex$" -and $saved -ine $PlanGuid) { $saved } else { '381b4222-f694-41f0-9685-ff5bb260df2e' }  # Balanced
    Log "Our power plan was still active from an earlier session; will restore $originalPlan." 'Yellow'
} else {
    $originalPlan = $activePlan
    Set-Content -Path $StateFile -Value $originalPlan -Encoding ASCII
}
Log "Power plan to restore afterwards: $originalPlan"

if (-not ((powercfg /list | Out-String) -match $PlanGuid)) {
    powercfg /duplicatescheme SCHEME_MIN $PlanGuid | Out-Null
    if ($LASTEXITCODE -ne 0) { powercfg /duplicatescheme SCHEME_BALANCED $PlanGuid | Out-Null }
    powercfg /changename $PlanGuid $PlanName 'Used by Smooth Midgar while FF7 Remake runs' | Out-Null
    Log "Created power plan '$PlanName'."
}

powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR PROCTHROTTLEMIN 100 | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PROCESSOR CPMINCORES 100      | Out-Null
powercfg /setacvalueindex $PlanGuid SUB_PCIEXPRESS ASPM 0             | Out-Null
powercfg /setacvalueindex $PlanGuid 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 | Out-Null
powercfg /setactive $PlanGuid | Out-Null
if ($LASTEXITCODE -eq 0) { Log "Performance power plan active (full clock, all cores awake)." 'Green' }
else { Log "Couldn't switch power plan (powercfg exit $LASTEXITCODE)." 'Yellow' }

try {
    # --- 2. Launch ---------------------------------------------------------
    if ($steamMode) {
        $exe = $gameCommand[0]
        $rest = @($gameCommand | Select-Object -Skip 1)
        if ($rest -notcontains $LaunchArgs) { $rest += $LaunchArgs }
        $dir = Split-Path -Parent $exe
        Start-Process -FilePath $exe -ArgumentList (Join-CommandArgs $rest) -WorkingDirectory $dir
        Log "Started: $exe $(Join-CommandArgs $rest)"
    } else {
        Log "Waiting for you to start the game from Epic ..."
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
    elseif (-not $isAdmin) { Log "Audio engine priority left as is (needs admin; the Engine.ini audio fixes still apply)." }

    Log "All set. Settings revert automatically when the game closes." 'Green'

    # --- 4. Watch until exit ----------------------------------------------
    while (Get-Process -Id $game.Id -ErrorAction SilentlyContinue) {
        Start-Sleep -Seconds 15
        if ($audioPid) {
            $current = Get-Process -Name audiodg -ErrorAction SilentlyContinue
            if ($current -and $current.Id -ne $audioPid) {
                $audioPid = Set-AudioPriority 'High'
                Log "Audio engine restarted by Windows; priority re-applied."
            }
        }
    }
    Log "Game closed."
}
finally {
    # --- 5. Restore --------------------------------------------------------
    Set-AudioPriority 'Normal' | Out-Null
    if ($originalPlan) { powercfg /setactive $originalPlan | Out-Null }
    Remove-Item $StateFile -ErrorAction SilentlyContinue
    Log "Restored your normal power plan." 'Green'
    if (-not $steamMode) { Start-Sleep -Seconds 3 }
}
