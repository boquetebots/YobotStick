# ===========================================================================
#  copy-extras.ps1  -  brings in what git cannot provide
# ===========================================================================
#
#  Called by build-stick.bat. Not something to run by hand.
#
#  Reads stick-extras.txt and copies each entry from the working stick into
#  the build. Fails - loudly, stopping the build - if any entry is missing,
#  because every line in that file is something whose absence has already
#  produced, or would produce, a broken or dangerous download.
#
#  This replaces the single hardcoded voice_cache copy. One mechanism, one
#  list, one place to look.
#
#  Prints one line per entry. Exit 0 all copied, 1 otherwise.
# ===========================================================================

param(
    [Parameter(Mandatory=$true)][string]$List,      # stick-extras.txt
    [Parameter(Mandatory=$true)][string]$Source,    # D:\Projects\YobotStick
    [Parameter(Mandatory=$true)][string]$Stick      # ...\build\stick
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -LiteralPath $List))   { Write-Output "[X] list not found: $List"; exit 1 }
    if (-not (Test-Path -LiteralPath $Source)) { Write-Output "[X] working stick not found: $Source"; exit 1 }

    $entries = @()
    foreach ($line in (Get-Content -LiteralPath $List)) {
        $e = $line.Trim()
        if ($e -eq '' -or $e.StartsWith('#')) { continue }
        $entries += $e.TrimEnd('\')
    }
    if ($entries.Count -eq 0) { Write-Output "[X] stick-extras.txt has no entries"; exit 1 }

    $missing = 0
    foreach ($rel in $entries) {
        $from = Join-Path $Source $rel
        $to   = Join-Path $Stick  $rel

        if (-not (Test-Path -LiteralPath $from)) {
            Write-Output "[X] MISSING on the working stick: $rel"
            $missing++
            continue
        }

        # Make sure the parent exists - gui\yobot.ico and the ohbotData files
        # land inside folders the git export already made, but do not assume it.
        $parent = Split-Path -Parent $to
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        if (Test-Path -LiteralPath $from -PathType Container) {
            Copy-Item -LiteralPath $from -Destination $to -Recurse -Force
            $n = (Get-ChildItem -LiteralPath $to -Recurse -File).Count
            Write-Output "    copied folder  $rel  ($n files)"
        } else {
            Copy-Item -LiteralPath $from -Destination $to -Force
            Write-Output "    copied file    $rel"
        }
    }

    if ($missing -gt 0) {
        Write-Output ""
        Write-Output "[X] $missing entr(y/ies) in stick-extras.txt are not on the working"
        Write-Output "    stick at $Source"
        Write-Output "    These cannot come from git. Nothing was published."
        exit 1
    }
    exit 0
}
catch {
    Write-Output "[X] $($_.Exception.Message)"
    exit 1
}
