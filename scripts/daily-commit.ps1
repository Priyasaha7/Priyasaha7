<#
.SYNOPSIS
    Appends a dated entry to a log file, then commits and pushes it.

.DESCRIPTION
    Meant to be run once per day by Task Scheduler. Uses whatever credential
    helper / SSH key git is already configured with -- no passwords in here.

.PARAMETER RepoPath
    Path to the git repository. Defaults to the repo this script lives in.

.PARAMETER Branch
    Branch to push to. Defaults to the current branch.

.PARAMETER NoPush
    Commit locally but skip the push (useful for testing).
#>
[CmdletBinding()]
param(
    [string]$RepoPath = (Split-Path -Parent $PSScriptRoot),
    [string]$Branch,
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    $logDir = Join-Path $RepoPath 'logs'
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path (Join-Path $logDir 'daily-commit.log') -Value $line -Encoding UTF8
}

if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
    throw "No git repository found at '$RepoPath'."
}

Push-Location $RepoPath
try {
    if (-not $Branch) {
        $Branch = (git rev-parse --abbrev-ref HEAD).Trim()
    }

    $today = Get-Date -Format 'yyyy-MM-dd'
    $activityFile = Join-Path $RepoPath 'activity.md'

    if (-not (Test-Path $activityFile)) {
        Set-Content -Path $activityFile -Value "# Activity Log`n" -Encoding UTF8
    }

    # One entry per day keeps the history meaningful instead of noisy.
    if (Select-String -Path $activityFile -SimpleMatch "- $today" -Quiet) {
        Write-Log "Entry for $today already exists. Nothing to do."
        exit 0
    }

    Add-Content -Path $activityFile -Value "- $today :: automated check-in" -Encoding UTF8

    git add -- activity.md
    if ((git diff --cached --name-only).Length -eq 0) {
        Write-Log 'No staged changes after add; skipping commit.' 'WARN'
        exit 0
    }

    git commit -m "chore: daily activity log for $today" | Out-Null
    Write-Log "Committed entry for $today on branch '$Branch'."

    if ($NoPush) {
        Write-Log 'NoPush specified; leaving commit local.'
        exit 0
    }

    git push origin $Branch
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Push to origin/$Branch failed with exit code $LASTEXITCODE." 'ERROR'
        exit $LASTEXITCODE
    }
    Write-Log "Pushed to origin/$Branch."
}
catch {
    Write-Log $_.Exception.Message 'ERROR'
    exit 1
}
finally {
    Pop-Location
}
