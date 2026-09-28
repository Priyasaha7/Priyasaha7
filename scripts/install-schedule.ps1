<#
.SYNOPSIS
    Registers (or re-registers) a Windows scheduled task that runs daily-commit.ps1.

.EXAMPLE
    .\scripts\install-schedule.ps1 -At 09:30
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'GithubDailyCommit',
    [datetime]$At = '09:00'
)

$ErrorActionPreference = 'Stop'

$repoPath   = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $PSScriptRoot 'daily-commit.ps1'

if (-not (Test-Path $scriptPath)) { throw "Cannot find '$scriptPath'." }

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`" -RepoPath `"$repoPath`"" `
    -WorkingDirectory $repoPath

$trigger  = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Description 'Daily GitHub activity commit' -Force | Out-Null

Write-Host "Registered task '$TaskName' to run daily at $($At.ToString('HH:mm'))."
Write-Host "Run now with:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Remove with:   Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
