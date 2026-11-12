<#
  Smooth Midgar (FF7R Legacy CPU Tuning) - Steam launch option helper.
  Dot-sourced by the installer and uninstaller.

  Steam keeps each game's launch options in
    <Steam>\userdata\<account>\config\localconfig.vdf
  and rewrites that file when it exits, so Steam must be closed while it is
  edited. Values in the file are escaped: \" for quotes, \\ for backslashes.
#>

$SteamAppId   = '1462040'
$LauncherDir  = Join-Path $env:LOCALAPPDATA 'SmoothMidgar'
$LauncherPath = Join-Path $LauncherDir 'FF7R-Launcher.ps1'
$PowerShellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Get-OurLaunchPrefix {
    "`"$PowerShellExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$LauncherPath`" %command%"
}

function ConvertFrom-VdfString([string]$s) { $s -replace '\\"', '"' -replace '\\\\', '\' }
function ConvertTo-VdfString([string]$s)   { $s -replace '\\', '\\' -replace '"', '\"' }

# Removes our wrapper (from any install location) and returns what's left:
# the user's own options, which come after %command%.
function Remove-OurLaunchPrefix([string]$opts) {
    $m = [regex]::Match($opts, '^\s*"[^"]*powershell\.exe"\s.*?-File\s+"[^"]*SmoothMidgar[^"]*\\FF7R-Launcher\.ps1"\s+%command%\s*(.*)$', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value.Trim() }
    return $opts.Trim()
}

function Get-SteamInfo {
    $steamPath = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
    if (-not $steamPath) { return $null }
    $steamPath = $steamPath -replace '/', '\'
    if (-not (Test-Path $steamPath)) { return $null }
    [pscustomobject]@{
        Path    = $steamPath
        Exe     = Join-Path $steamPath 'steam.exe'
        Configs = @(Get-ChildItem (Join-Path $steamPath 'userdata\*\config\localconfig.vdf') -ErrorAction SilentlyContinue)
    }
}

function Stop-SteamForEdit($steam) {
    if (-not (Get-Process steam -ErrorAction SilentlyContinue)) { return $false }
    Write-Host 'Closing Steam for a moment so the launch option can be saved...'
    & $steam.Exe -shutdown
    $t = 0
    while ((Get-Process steam -ErrorAction SilentlyContinue) -and $t -lt 60) { Start-Sleep 2; $t += 2 }
    if (Get-Process steam -ErrorAction SilentlyContinue) { throw 'Steam did not close. Exit Steam yourself and run this again.' }
    return $true
}

# Mode 'add' puts our wrapper in front of the user's own options; 'remove'
# takes it out and keeps theirs. Returns 'changed', 'notfound' or 'conflict'.
function Update-LaunchOptions([string]$file, [string]$mode) {
    # Keep the file exactly as Steam wrote it apart from the one line we change
    # (Steam uses LF line endings).
    $raw = [System.IO.File]::ReadAllText($file)
    $nl = if ($raw.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = [System.Collections.Generic.List[string]]($raw -split '\r?\n')
    $start = -1
    for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        if ($lines[$i] -match ('^(\t+)"' + $SteamAppId + '"\s*$') -and $lines[$i + 1] -match '^\t+\{\s*$') { $start = $i; break }
    }
    if ($start -lt 0) { return 'notfound' }
    $indent = ([regex]::Match($lines[$start], '^\t+').Value) + "`t"
    $depth = 0; $optLine = -1
    for ($j = $start + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j] -match '^\s*\{\s*$') { $depth++ }
        elseif ($lines[$j] -match '^\s*\}\s*$') { $depth--; if ($depth -eq 0) { break } }
        elseif ($depth -eq 1 -and $lines[$j] -match '^\t+"LaunchOptions"\s+"(.*)"\s*$') { $optLine = $j }
    }
    $current = ''
    if ($optLine -ge 0) {
        $current = ConvertFrom-VdfString ([regex]::Match($lines[$optLine], '^\t+"LaunchOptions"\s+"(.*)"\s*$').Groups[1].Value)
    }
    $theirs = Remove-OurLaunchPrefix $current
    if ($mode -eq 'add') {
        if ($theirs -match '%command%') { return 'conflict' }   # another wrapper is already set
        $new = ("$(Get-OurLaunchPrefix) $theirs").Trim()
    } else {
        if ($theirs -eq $current.Trim()) { return 'unchanged' }
        $new = $theirs
    }
    $newLine = "$indent`"LaunchOptions`"`t`t`"$(ConvertTo-VdfString $new)`""
    if ($mode -ne 'add' -and $new -eq '' -and $optLine -ge 0) { $lines.RemoveAt($optLine) }  # nothing of theirs left
    elseif ($optLine -ge 0) { $lines[$optLine] = $newLine }
    else { $lines.Insert($start + 2, $newLine) }

    $backup = "$file.smoothmidgar-backup"
    if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $file $backup }
    [System.IO.File]::WriteAllText($file, ($lines -join $nl), (New-Object System.Text.UTF8Encoding($false)))
    return 'changed'
}
