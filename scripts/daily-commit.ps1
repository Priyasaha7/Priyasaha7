<#
.SYNOPSIS
    Appends a dated entry to a log file, then commits and pushes it.

.DESCRIPTION
    Meant to be run once per day by Task Scheduler. Reads GITHUB_USERNAME and
    GITHUB_TOKEN from a gitignored .env file; falls back to git's own credential
    helper when .env is absent. GitHub does not accept account passwords for git
    operations, so GITHUB_TOKEN must be a Personal Access Token.

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

function Import-DotEnv {
    param([string]$Path)
    $values = @{}
    if (-not (Test-Path $Path)) { return $values }
    foreach ($line in Get-Content -Path $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        $split = $trimmed.IndexOf('=')
        if ($split -lt 1) { continue }
        $key = $trimmed.Substring(0, $split).Trim()
        $value = $trimmed.Substring($split + 1).Trim().Trim('"', "'")
        $values[$key] = $value
    }
    return $values
}

if (-not (Test-Path (Join-Path $RepoPath '.git'))) {
    throw "No git repository found at '$RepoPath'."
}

$env_ = Import-DotEnv -Path (Join-Path $RepoPath '.env')

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

    $commitArgs = @()
    if ($env_['GIT_AUTHOR_NAME'] -and $env_['GIT_AUTHOR_EMAIL']) {
        $commitArgs += @('-c', "user.name=$($env_['GIT_AUTHOR_NAME'])")
        $commitArgs += @('-c', "user.email=$($env_['GIT_AUTHOR_EMAIL'])")
    }

    git @commitArgs commit -m "chore: daily activity log for $today" | Out-Null
    Write-Log "Committed entry for $today on branch '$Branch'."

    if ($NoPush) {
        Write-Log 'NoPush specified; leaving commit local.'
        exit 0
    }

    $token = $env_['GITHUB_TOKEN']
    $user  = $env_['GITHUB_USERNAME']

    if ($token -and $token -ne 'github_pat_replace_me' -and $user) {
        if ($token -notmatch '^(gh[pousr]_|github_pat_)') {
            Write-Log 'GITHUB_TOKEN does not look like a Personal Access Token. GitHub rejects account passwords for git operations; create a token at https://github.com/settings/tokens' 'ERROR'
            exit 1
        }
        $remote = (git remote get-url origin).Trim()
        if ($remote -notmatch '^https://github\.com/(.+?)(?:\.git)?$') {
            Write-Log "Token auth needs an https github.com remote, but origin is '$remote'." 'ERROR'
            exit 1
        }
        # Kept inline so the token is never written to .git/config.
        $authUrl = "https://$([uri]::EscapeDataString($user)):$([uri]::EscapeDataString($token))@github.com/$($Matches[1]).git"
        git push $authUrl "HEAD:$Branch" --quiet 2>&1 |
            ForEach-Object { $_ -replace [regex]::Escape($token), '***' } |
            ForEach-Object { Write-Log $_ }
    }
    else {
        Write-Log 'No token in .env; using git credential helper.'
        git push origin $Branch
    }

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
