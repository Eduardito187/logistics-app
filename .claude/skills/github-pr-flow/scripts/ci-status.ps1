# One-shot read of the latest run of every workflow on a branch (public repos need no token).
# Do not loop/poll this: read once, report, and let the user ask again.
# Usage: ci-status.ps1 -Repo logistics -Branch feature/x
param(
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Branch,
    [string] $Owner = 'Eduardito187'
)
$ErrorActionPreference = 'Stop'
$base = "https://api.github.com/repos/$Owner/$Repo"
$runs = Invoke-RestMethod -Uri "$base/actions/runs?branch=$([uri]::EscapeDataString($Branch))&per_page=20"
$latest = $runs.workflow_runs | Group-Object name | ForEach-Object { $_.Group | Sort-Object created_at -Descending | Select-Object -First 1 }
foreach ($run in $latest) {
    $jobs = Invoke-RestMethod -Uri "$base/actions/runs/$($run.id)/jobs"
    foreach ($job in $jobs.jobs) {
        '{0,-15} {1,-35} {2,-12} {3,-10} {4}' -f $run.name, $job.name, $job.status, $job.conclusion, $run.head_sha.Substring(0, 7)
    }
}
