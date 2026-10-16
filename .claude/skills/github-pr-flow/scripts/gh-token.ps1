# Returns the GitHub token stored by Git Credential Manager. Never print it.
# PowerShell 5.1 corrupts stdin for native commands, so the query goes through a file (LF, no BOM)
# and cmd.exe, run from a non-UNC directory (cmd refuses UNC working directories).
$ErrorActionPreference = 'Stop'
Push-Location $env:TEMP
try {
    $query = Join-Path $env:TEMP ("cred-query-" + [guid]::NewGuid() + ".txt")
    [IO.File]::WriteAllText($query, "protocol=https`nhost=github.com`n`n", (New-Object System.Text.UTF8Encoding $false))
    $cred = cmd /c "git credential fill < `"$query`""
    Remove-Item $query -Force
} finally {
    Pop-Location
}
$token = ($cred | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
if (-not $token) { throw 'No GitHub credential in Git Credential Manager. Ask the user to run one git push from their own terminal to sign in.' }
return $token
