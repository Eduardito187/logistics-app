# Instala (o re-exporta) las memorias del proyecto desde/hacia el espejo versionado.
#
# Las memorias de Claude Code viven FUERA del repo, en:
#   $env:USERPROFILE\.claude\projects\<slug>\memory\
# donde <slug> = ruta absoluta del proyecto con los separadores vueltos '-'.
# Este espejo (.claude\memory\) viaja con git; el script lo sincroniza con el
# dir del usuario en CUALQUIER maquina/ruta, calculando el slug solo.
#
# Uso (PowerShell, desde la raiz del repo o cualquier lado):
#   .\.claude\memory\install.ps1            # repo  -> dir del usuario (default)
#   .\.claude\memory\install.ps1 -Export    # dir del usuario -> repo (para versionar cambios)
param([switch]$Export)
$ErrorActionPreference = 'Stop'

# Raiz del repo = carpeta padre de este script (.claude\memory -> .claude -> repo).
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = (Resolve-Path (Join-Path $scriptDir '..\..')).Path

# Slug: ruta absoluta con '/', '\' y ':' -> '-'  (p. ej. C:\dev\logistics-app -> C--dev-logistics-app)
$slug = ($repoRoot -replace '[/\\:]', '-')
$userDir = Join-Path $env:USERPROFILE ".claude\projects\$slug\memory"

if ($Export) {
  $src = $userDir; $dst = $scriptDir
  Write-Host "Exportando memorias del usuario -> espejo del repo"
} else {
  $src = $scriptDir; $dst = $userDir
  Write-Host "Instalando memorias del repo -> dir del usuario"
}

New-Item -ItemType Directory -Force -Path $dst | Out-Null
$files = Get-ChildItem -Path $src -Filter *.md -File
if (-not $files) { throw "No hay .md en $src" }
foreach ($f in $files) { Copy-Item -Force $f.FullName (Join-Path $dst $f.Name) }

Write-Host "Listo. Ruta del proyecto: $repoRoot"
Write-Host "Slug:                     $slug"
Write-Host "Dir de memorias:          $userDir"
