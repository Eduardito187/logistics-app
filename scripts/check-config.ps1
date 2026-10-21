<#
.SYNOPSIS
  Revisa que claves faltan o estan vacias en config/*.json. NUNCA imprime valores.

.DESCRIPTION
  Para cada config/<entorno>.json (dev, staging, production) lista cada clave como:
    OK      presente, con valor y con formato esperado
    VACIA   la clave existe pero esta en ""
    FALTA   la clave no esta en el archivo
    FORMATO tiene valor pero no tiene la forma esperada (no se muestra el valor)
  Las claves "requeridas" hacen fallar el script (exit 1); las "opcionales" solo informan.
  Ver docs/firebase-setup.md para saber de donde sale cada valor.

.PARAMETER Env
  Revisar solo estos entornos (p. ej. -Env staging,production). Default: todos los config/*.json.

.PARAMETER AllowEmptyDev
  No fallar por claves vacias en dev.json (dev suele correr sin Firebase).

.EXAMPLE
  .\scripts\check-config.ps1
  .\scripts\check-config.ps1 -Env production
#>
[CmdletBinding()]
param(
  [string[]]$Env = @(),
  [switch]$AllowEmptyDev
)

$ErrorActionPreference = 'Stop'
$AppRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$ConfigDir = Join-Path $AppRoot 'config'

# Clave -> regex de formato esperado ('' = cualquier valor no vacio).
$Required = [ordered]@{
  'ENV'                          = '^(dev|staging|production)$'
  'API_BASE_URL'                 = '^https?://'
  'LABEL_PUBLIC_KEYS'            = ''
  'FIREBASE_API_KEY'             = '^AIza[0-9A-Za-z_\-]{30,}$'
  'FIREBASE_APP_ID'              = '^1:\d+:android:[0-9a-f]+$'
  'FIREBASE_MESSAGING_SENDER_ID' = '^\d+$'
  'FIREBASE_PROJECT_ID'          = '^[a-z0-9\-]+$'
  'FIREBASE_IOS_APP_ID'          = '^1:\d+:ios:[0-9a-f]+$'
  'FIREBASE_IOS_BUNDLE_ID'       = '^bo\.com\.dismac\.logisticsApp$'
}
$Optional = [ordered]@{
  'FIREBASE_IOS_API_KEY' = '^AIza[0-9A-Za-z_\-]{30,}$'
  'APP_UPDATE_URL'       = '^https?://'
  'MAP_TILES_URL'        = '^https?://'
}

$files = Get-ChildItem $ConfigDir -Filter '*.json' | Sort-Object Name
if ($Env.Count -gt 0) { $files = $files | Where-Object { $Env -contains $_.BaseName } }
if (-not $files) { Write-Host "No hay config/*.json para revisar en $ConfigDir"; exit 1 }

$failed = $false
foreach ($file in $files) {
  Write-Host ''
  Write-Host "config/$($file.Name)" -ForegroundColor Cyan
  try {
    $json = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Write-Host '  JSON invalido (no se pudo leer)' -ForegroundColor Red
    $failed = $true
    continue
  }
  $props = @{}
  foreach ($p in $json.PSObject.Properties) { $props[$p.Name] = [string]$p.Value }

  $isDev = $file.BaseName -eq 'dev'
  foreach ($group in @(@{ Keys = $Required; Req = $true }, @{ Keys = $Optional; Req = $false })) {
    foreach ($key in $group.Keys.Keys) {
      $pattern = $group.Keys[$key]
      $tag = if ($group.Req) { 'requerida' } else { 'opcional ' }
      if (-not $props.ContainsKey($key)) {
        $state = 'FALTA'
      } elseif ($props[$key].Trim() -eq '') {
        $state = 'VACIA'
      } elseif ($pattern -ne '' -and $props[$key] -notmatch $pattern) {
        $state = 'FORMATO'
      } else {
        $state = 'OK'
      }
      # ENV debe coincidir con el nombre del archivo.
      if ($state -eq 'OK' -and $key -eq 'ENV' -and $props[$key] -ne $file.BaseName) { $state = 'FORMATO' }

      $color = switch ($state) { 'OK' { 'Green' } 'FORMATO' { 'Red' } default { if ($group.Req) { 'Yellow' } else { 'DarkGray' } } }
      Write-Host ("  {0,-8} {1}  {2}" -f $state, $tag, $key) -ForegroundColor $color

      if ($group.Req -and $state -ne 'OK') {
        $tolerated = $isDev -and $AllowEmptyDev -and ($state -eq 'VACIA' -or $state -eq 'FALTA')
        if (-not $tolerated) { $failed = $true }
      }
      if (-not $group.Req -and $state -eq 'FORMATO') { $failed = $true }
    }
  }
  $extra = $props.Keys | Where-Object { -not $Required.Contains($_) -and -not $Optional.Contains($_) }
  foreach ($k in $extra) { Write-Host ("  {0,-8} {1}  {2}" -f 'EXTRA', 'no usada', $k) -ForegroundColor DarkGray }
}

Write-Host ''
if ($failed) {
  Write-Host 'Faltan claves requeridas o hay formatos invalidos (ver docs/firebase-setup.md).' -ForegroundColor Yellow
  exit 1
}
Write-Host 'Configuracion completa.' -ForegroundColor Green
exit 0
