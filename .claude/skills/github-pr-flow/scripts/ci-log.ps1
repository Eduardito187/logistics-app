# Prints the relevant lines of the failing jobs of the latest failed run on a branch.
# Job logs require a token even on public repos.
# Usage: ci-log.ps1 -Repo logistics -Branch feature/x [-Context 25]
param(
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Branch,
    [string] $Owner = 'Eduardito187',
    [int] $Context = 25
)
$ErrorActionPreference = 'Stop'
$token = & (Join-Path $PSScriptRoot 'gh-token.ps1')
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
$base = "https://api.github.com/repos/$Owner/$Repo"

$runs = Invoke-RestMethod -Headers $headers -Uri "$base/actions/runs?branch=$([uri]::EscapeDataString($Branch))&per_page=20"
$run = $runs.workflow_runs | Where-Object { $_.conclusion -eq 'failure' } | Select-Object -First 1
if (-not $run) { Write-Output 'No failed runs on this branch.'; return }

$jobs = Invoke-RestMethod -Headers $headers -Uri "$base/actions/runs/$($run.id)/jobs"
foreach ($job in $jobs.jobs | Where-Object { $_.conclusion -eq 'failure' }) {
    Write-Output "=== $($run.name) / $($job.name) ($($run.head_sha.Substring(0, 7)))"
    $log = Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri "$base/actions/jobs/$($job.id)/logs"
    $text = if ($log.Content -is [string]) { $log.Content } else { [Text.Encoding]::UTF8.GetString($log.Content) }
    # The real error is usually in the step right before "##[error]Process completed": show that step
    $lines = $text -split "`n"
    $err = ($lines | Select-String -Pattern '##\[error\]' | Select-Object -First 1).LineNumber
    if ($err) { $lines[[Math]::Max(0, $err - 1 - $Context)..($err - 1)] } else { $lines | Select-Object -Last $Context }
}
