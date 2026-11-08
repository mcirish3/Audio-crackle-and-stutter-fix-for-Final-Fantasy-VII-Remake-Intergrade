<#
.SYNOPSIS
  FF7R Legacy CPU Tuning - installer.

.DESCRIPTION
  Detects this PC's CPU threads, GPU memory and system RAM, then writes a
  tuned Engine.ini for Final Fantasy VII Remake Intergrade into:
    Documents\My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor\

  Your original Engine.ini (if any) is backed up once as
  Engine.ini.pre-legacytuning.bak, and restored by the uninstaller.

  Also checks that the game and FFVIIHook are installed, and warns if not.
  Does not need admin rights.

.PARAMETER VramGB
  Override detected GPU memory (GB), e.g. -VramGB 8

.PARAMETER Threads
  Override detected CPU thread count, e.g. -Threads 6
#>
param(
    [int]$VramGB = 0,
    [int]$Threads = 0
)

$ErrorActionPreference = 'Stop'
$Version = '1.0.0'
$Marker  = 'FF7R Legacy CPU Tuning'

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

Say ""
Say "=== $Marker v$Version - installer ===" 'Cyan'
Say ""

# ---------------------------------------------------------------------------
# 1. Detect hardware
# ---------------------------------------------------------------------------
$cpus     = @(Get-CimInstance Win32_Processor)
$cpuName  = ($cpus[0].Name -replace '\s+', ' ').Trim()
$detThreads = ($cpus | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
if ($Threads -gt 0) { $detThreads = $Threads }

$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)

# GPU memory: Win32_VideoController caps at 4 GB, so read the driver's
# 64-bit value from the registry first.
function Get-VramBytes {
    $best = [uint64]0
    $classKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
    Get-ChildItem $classKey -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object {
        $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
        foreach ($name in 'HardwareInformation.qwMemorySize', 'HardwareInformation.MemorySize') {
            $v = $p.$name
            if ($null -eq $v) { continue }
            if ($v -is [byte[]]) {
                if ($v.Length -ge 8) { $v = [BitConverter]::ToUInt64($v, 0) }
                elseif ($v.Length -ge 4) { $v = [BitConverter]::ToUInt32($v, 0) }
                else { continue }
            }
            $v = [uint64]$v
            if ($v -gt $best) { $best = $v }
        }
    }
    if ($best -eq 0) {
        $best = [uint64](Get-CimInstance Win32_VideoController | Measure-Object -Property AdapterRAM -Maximum).Maximum
    }
    return $best
}

$gpu = Get-CimInstance Win32_VideoController |
       Where-Object { $_.Name -notmatch 'Basic Display|Remote|Virtual|Parsec|Meta' } |
       Sort-Object AdapterRAM -Descending | Select-Object -First 1
$gpuName = if ($gpu) { $gpu.Name } else { 'Unknown GPU' }

$detVram = [math]::Round((Get-VramBytes) / 1GB)
if ($VramGB -gt 0) { $detVram = $VramGB }

Say "Detected:"
Say ("  CPU  {0}  ({1} threads)" -f $cpuName, $detThreads)
Say ("  GPU  {0}  ({1} GB)" -f $gpuName, $detVram)
Say ("  RAM  {0} GB" -f $ramGB)
if ($detVram -le 0) {
    Say "  Couldn't read GPU memory; assuming 8 GB. Re-run with -VramGB <n> to override." 'Yellow'
    $detVram = 8
}

# ---------------------------------------------------------------------------
# 2. Pick values
# ---------------------------------------------------------------------------
# Audio: fewer threads -> fewer decode workers and more buffer headroom.
if     ($detThreads -le 4) { $audioWorkers = 2; $audioChannels = 28; $audioBuffer = 3072 }
elseif ($detThreads -le 6) { $audioWorkers = 3; $audioChannels = 30; $audioBuffer = 2048 }
else                       { $audioWorkers = 4; $audioChannels = 32; $audioBuffer = 2048 }

# Texture streaming pool (MB) on top of the game's base VRAM use at max settings.
if     ($detVram -le 4)  { $pool = 1000 }
elseif ($detVram -le 6)  { $pool = 1800 }
elseif ($detVram -le 8)  { $pool = 2850 }
elseif ($detVram -le 11) { $pool = 4500 }
else                     { $pool = 5700 }

$ioCache = if ($ramGB -ge 16) { 512 } else { 256 }

if ($detVram -le 4) {
    Say "  Note: 4 GB cards are tight at max texture settings. If textures load late, set Texture Resolution to Low in game." 'Yellow'
}

# ---------------------------------------------------------------------------
# 3. Check the game and FFVIIHook (warnings only)
# ---------------------------------------------------------------------------
function Find-GameBin {
    $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steam) { $steam = "${env:ProgramFiles(x86)}\Steam" }
    $libs = @($steam)
    $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' | ForEach-Object {
            $libs += ($_.Matches[0].Groups[1].Value -replace '\\\\', '\')
        }
    }
    foreach ($lib in ($libs | Select-Object -Unique)) {
        $bin = Join-Path $lib 'steamapps\common\FINAL FANTASY VII REMAKE\End\Binaries\Win64'
        if (Test-Path (Join-Path $bin 'ff7remake_.exe')) { return $bin }
    }
    return $null
}

$bin = Find-GameBin
if ($bin) {
    Say ""
    Say "Game found: $bin"
    $hookNames = 'xinput1_3.dll', 'XAPOFX1_5.dll', 'X3DAudio1_7.dll', 'dsound.dll'
    $hook = $hookNames | Where-Object { Test-Path (Join-Path $bin $_) } | Select-Object -First 1
    if ($hook) {
        Say "FFVIIHook found ($hook)." 'Green'
    } else {
        Say "FFVIIHook NOT found next to ff7remake_.exe." 'Yellow'
        Say "Without it the game ignores Engine.ini. Get it from Nexus (FF7 Remake mod 74)" 'Yellow'
        Say "and put xinput1_3.dll in: $bin" 'Yellow'
    }
} else {
    Say ""
    Say "Steam copy of the game not found automatically (Epic, or an unusual library)." 'Yellow'
    Say "That's fine: make sure FFVIIHook's xinput1_3.dll sits next to ff7remake_.exe." 'Yellow'
}

# ---------------------------------------------------------------------------
# 4. Write Engine.ini
# ---------------------------------------------------------------------------
$docs = [Environment]::GetFolderPath('MyDocuments')   # handles OneDrive redirection
$cfgDir = Join-Path $docs 'My Games\FINAL FANTASY VII REMAKE\Saved\Config\WindowsNoEditor'
New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
$ini    = Join-Path $cfgDir 'Engine.ini'
$backup = "$ini.pre-legacytuning.bak"

if ((Test-Path $ini) -and -not (Test-Path $backup)) {
    $existing = Get-Content $ini -Raw -ErrorAction SilentlyContinue
    if ($existing -notmatch [regex]::Escape($Marker)) {
        Copy-Item $ini $backup
        Say ""
        Say "Your existing Engine.ini was backed up to:"
        Say "  $backup"
    }
}

$template = Get-Content (Join-Path $PSScriptRoot 'Engine.template.ini') -Raw
$values = @{
    VERSION        = $Version
    DATE           = (Get-Date -Format 'yyyy-MM-dd')
    CPU_NAME       = $cpuName
    CORES          = $detThreads
    GPU_NAME       = $gpuName
    VRAM_GB        = $detVram
    RAM_GB         = $ramGB
    AUDIO_BUFFER   = $audioBuffer
    AUDIO_CHANNELS = $audioChannels
    AUDIO_WORKERS  = $audioWorkers
    POOL_SIZE      = $pool
    IO_CACHE       = $ioCache
}
foreach ($k in $values.Keys) { $template = $template.Replace("{{$k}}", [string]$values[$k]) }
if ($template -match '\{\{[A-Z_]+\}\}') { throw "Template has unfilled values: $($Matches[0])" }

[IO.File]::WriteAllText($ini, ($template -replace "`r?`n", "`r`n"), [Text.Encoding]::ASCII)

Say ""
Say "Engine.ini written:" 'Green'
Say "  $ini"
Say ("  Audio: {0} channels, {1}-frame buffers, {2} workers" -f $audioChannels, $audioBuffer, $audioWorkers)
Say ("  Streaming pool: {0} MB, I/O cache: {1} MB" -f $pool, $ioCache)
Say ""
Say "Done. Start the game with '2 - Play FF7R.bat' from now on." 'Cyan'
Say ""
