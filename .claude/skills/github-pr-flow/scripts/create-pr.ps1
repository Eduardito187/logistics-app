# Creates (or retitles) a PR. Title and body are read from UTF-8 files: never put accented
# text as a literal inside a .ps1 (PowerShell 5.1 reads BOM-less scripts as Windows-1252).
#
# Usage:
#   create-pr.ps1 -Repo logistics -Head feature/x -Base dev -TitleFile title.txt -BodyFile body.md
#   create-pr.ps1 -Repo logistics -Number 3 -TitleFile title.txt      # only fix the title
param(
    [Parameter(Mandatory)] [string] $Repo,
    [string] $Owner = 'Eduardito187',
    [string] $Head,
    [string] $Base = 'dev',
    [int] $Number = 0,
    [Parameter(Mandatory)] [string] $TitleFile,
    [string] $BodyFile
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding $false
$token = & (Join-Path $PSScriptRoot 'gh-token.ps1')
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }

$payload = @{ title = [IO.File]::ReadAllText((Resolve-Path $TitleFile), $utf8).Trim() }
if ($BodyFile) { $payload.body = [IO.File]::ReadAllText((Resolve-Path $BodyFile), $utf8) }

if ($Number -gt 0) {
    $method = 'Patch'; $uri = "https://api.github.com/repos/$Owner/$Repo/pulls/$Number"
} else {
    if (-not $Head) { throw '-Head is required to create a PR' }
    $payload.head = $Head; $payload.base = $Base
    $method = 'Post'; $uri = "https://api.github.com/repos/$Owner/$Repo/pulls"
}

$res = Invoke-WebRequest -UseBasicParsing -Method $method -Uri $uri -Headers $headers `
    -Body $utf8.GetBytes(($payload | ConvertTo-Json -Compress)) -ContentType 'application/json; charset=utf-8'
$pr = $utf8.GetString($res.RawContentStream.ToArray()) | ConvertFrom-Json

# Encoding check on the bytes GitHub stored: C3 83 / C3 82 are the mojibake signature (U+00C3 / U+00C2)
$hex = ($utf8.GetBytes($pr.title) | ForEach-Object { $_.ToString('X2') }) -join ''
$mojibake = $hex.Contains('C383') -or $hex.Contains('C382')
Write-Output "$Repo #$($pr.number) $($pr.html_url) | mojibake: $mojibake"
if ($mojibake) { throw 'Title stored with mojibake: check the title file is UTF-8.' }
