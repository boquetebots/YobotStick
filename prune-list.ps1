# ===========================================================================
#  prune-list.ps1  -  works out what build-stick.bat should delete
# ===========================================================================
#
#  Called by build-stick.bat. Not something to run by hand.
#
#  WHY THIS EXISTS, rather than findstr in the .bat
#  ------------------------------------------------
#  The job is simple: for each entry in a folder, is its path listed in
#  stick-manifest.txt, yes or no. findstr was tried and got it wrong twice in
#  one hour, both times silently:
#
#    1. Given a manifest with bare LF line endings, findstr does not see
#       separate lines at all, so /x - match a whole line exactly - matched
#       nothing and the build deleted all 105 files it looked at.
#
#    2. With that fixed, findstr /c: still failed on the one entry whose name
#       begins with a dot - OhbotPi2\.env.example - because of how it handles
#       a backslash followed by a dot in a "literal" search string. 82 of 83
#       right is worse than obviously broken: it deleted the keys template and
#       nothing else, and only the manifest check two steps later noticed.
#
#  Two silent wrong answers from the same tool is enough. PowerShell does
#  ordinary string comparison with no escaping rules, reads either kind of
#  line ending, and is on every Windows machine.
#
#  Writes two files and prints nothing:
#     to-drop.txt       one path per line, relative to the top of the stick
#     prune-counts.txt  "<kept> <dropped>"
#
#  Exit code 0 on success, 1 on anything it could not do.
# ===========================================================================

param(
    [Parameter(Mandatory=$true)][string]$Manifest,   # stick-manifest.txt
    [Parameter(Mandatory=$true)][string]$Stick,      # ...\build\stick
    [Parameter(Mandatory=$true)][string]$OutDir      # ...\build
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -LiteralPath $Manifest)) {
        Write-Error "manifest not found: $Manifest"; exit 1
    }

    # Get-Content copes with CRLF or LF. Skip comments and blank lines, and
    # trim, so a stray trailing space in the manifest cannot delete a file.
    $allowed = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($line in (Get-Content -LiteralPath $Manifest)) {
        $e = $line.Trim()
        if ($e -eq '' -or $e.StartsWith('#')) { continue }
        [void]$allowed.Add($e.TrimEnd('\'))
    }
    if ($allowed.Count -eq 0) { Write-Error "manifest has no entries"; exit 1 }

    # Only these are filtered. Everything deeper comes across whole.
    #
    # ohbotData was added 2026-09-20 after the git export's stale
    # MotorDefinitionsYobot.omd - superseded by the 3-point calibration in
    # August - reached a stick and the robot thrashed against its stops.
    # Naming that one bad file would have been the same mistake as before, so
    # the folder is filtered by the manifest like the others.
    $pruned = @('OhbotPi2', 'OhbotPi2\Windows', 'OhbotPi2\ohbotData', 'Chess')

    $drop = New-Object System.Collections.ArrayList
    $kept = 0

    foreach ($folder in $pruned) {
        $full = Join-Path $Stick $folder
        if (-not (Test-Path -LiteralPath $full)) { continue }
        # -Force so dot-files and anything flagged hidden are seen. Missing
        # them would silently ship a file the manifest never approved.
        foreach ($child in (Get-ChildItem -LiteralPath $full -Force)) {
            $rel = Join-Path $folder $child.Name
            if ($allowed.Contains($rel)) { $kept++ } else { [void]$drop.Add($rel) }
        }
    }

    Set-Content -LiteralPath (Join-Path $OutDir 'to-drop.txt') -Value $drop
    Set-Content -LiteralPath (Join-Path $OutDir 'prune-counts.txt') -Value "$kept $($drop.Count)"
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
