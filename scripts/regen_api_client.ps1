<#
.SYNOPSIS
  Regenera el cliente Dart del API (lib/core/api/) desde openapi/v1.yaml del backend.

.DESCRIPTION
  Regla #5 de CLAUDE.md: los DTOs del API no se escriben a mano, salen de aqui.
  Ver docs/cliente-api.md para el porque de cada paso.

  Pasos (todo en una carpeta temporal; el proyecto solo se toca al final):
    1. Copia el spec del backend a <tmp>/openapi/v1.yaml.
    2. Preprocesa a v1.json (anchors YAML + parameters de nivel path) con la
       Python de Windows si tiene PyYAML; si no, con la Python de WSL.
    3. pub get con tool/api_gen/pubspec.yaml + pubspec.lock y el Dart 3.13 de
       C:\sdk\flutter (retrofit_generator ^10.2.12 no corre en Dart 3.8).
    4. dart run swagger_parser + parche `MetaSealed?` + build_runner build.
    5. dart format con el Dart 3.8 del proyecto (C:\flutter), --language-version=3.8.
    6. Compara los tipos anonimos DataN viejos vs nuevos y avisa si se renumeraron,
       listando las referencias fuera de lib/core/api.
    7. Sin -DryRun ni -Out: reemplaza lib/core/api/ y openapi/v1.{yaml,json} del proyecto.
       Con -DryRun: deja el resultado en una carpeta temporal y muestra el diff.

  No toca pubspec.yaml / pubspec.lock del proyecto ni corre pub get en el proyecto.

.PARAMETER Spec
  Ruta al openapi/v1.yaml del backend. Default: el repo backend en WSL.

.PARAMETER Out
  Carpeta raiz donde dejar el resultado (<Out>\lib\core\api). No toca el proyecto.

.PARAMETER DryRun
  Genera en una carpeta temporal y compara contra lib/core/api del proyecto.

.EXAMPLE
  .\scripts\regen_api_client.ps1 -DryRun
  .\scripts\regen_api_client.ps1 -Spec .\openapi\v1.yaml -DryRun
  .\scripts\regen_api_client.ps1                     # aplica al proyecto
#>
[CmdletBinding()]
param(
  [string]$Spec = '\\wsl.localhost\Ubuntu-22.04\dismac\logistics\openapi\v1.yaml',
  [string]$Out = '',
  [switch]$DryRun,
  [string]$GenFlutter = 'C:\sdk\flutter',
  [string]$ProjectFlutter = 'C:\flutter',
  [string]$WslDistro = 'Ubuntu-22.04',
  [switch]$KeepWork
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Step([string]$msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Fail([string]$msg) { Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }
function Invoke-Native([string]$exe, [string[]]$argv, [string]$what) {
  & $exe @argv
  if ($LASTEXITCODE -ne 0) { Fail "$what fallo (exit $LASTEXITCODE)" }
}
# C:\x\y -> C:/x/y (wslpath y git aceptan barras normales).
function To-Slash([string]$p) { return $p -replace '\\', '/' }

$AppRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).ProviderPath
$GenDart = Join-Path $GenFlutter 'bin\dart.bat'
$FmtDart = Join-Path $ProjectFlutter 'bin\dart.bat'
$ApiRel = 'lib\core\api'
$ProjectApi = Join-Path $AppRoot $ApiRel

if (-not (Test-Path $Spec)) { Fail "no se encontro el spec del backend: $Spec (pasalo con -Spec)" }
if (-not (Test-Path $GenDart)) { Fail "no esta el Dart de generacion: $GenDart (Flutter >= 3.35 en -GenFlutter)" }
if (-not (Test-Path $FmtDart)) { Fail "no esta el Dart del proyecto: $FmtDart (-ProjectFlutter)" }
$Spec = (Resolve-Path $Spec).ProviderPath

# Carpeta temporal con ruta larga (sin nombres 8.3: wslpath los necesita reales).
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$Work = Join-Path $env:LOCALAPPDATA "Temp\logistics-api-gen\$stamp"
New-Item -ItemType Directory -Force -Path (Join-Path $Work 'openapi') | Out-Null
Write-Host "Carpeta de trabajo: $Work"

$Apply = (-not $DryRun) -and ($Out -eq '')
if ($DryRun -and $Out -eq '') { $Out = Join-Path $Work 'out' }

# --- 1. Spec ------------------------------------------------------------------
Step "[1/7] Copiando spec: $Spec"
Copy-Item $Spec (Join-Path $Work 'openapi\v1.yaml')

# --- 2. Preprocesado ----------------------------------------------------------
Step '[2/7] Preprocesando YAML -> JSON'
$pre = Join-Path $AppRoot 'scripts\preprocess_openapi.py'
$yamlIn = Join-Path $Work 'openapi\v1.yaml'
$jsonOut = Join-Path $Work 'openapi\v1.json'
$winPy = $null
foreach ($cand in @('python', 'py')) {
  if (Get-Command $cand -ErrorAction SilentlyContinue) {
    # En PS 5.1 el stderr de un nativo con Stop se vuelve excepcion: sondear con Continue.
    $prevEap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & $cand -I -c 'import yaml' 2>&1 | Out-Null
    $code = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($code -eq 0) { $winPy = $cand; break }
  }
}
if ($winPy) {
  Write-Host "    Python de Windows ($winPy) con PyYAML"
  Invoke-Native $winPy @('-I', $pre, $yamlIn, $jsonOut) 'preprocess_openapi.py'
} else {
  Write-Host "    Python de Windows sin PyYAML -> python3 de WSL ($WslDistro)"
  $wPre = (& wsl.exe -d $WslDistro -e wslpath -a (To-Slash $pre)).Trim()
  $wIn = (& wsl.exe -d $WslDistro -e wslpath -a (To-Slash $yamlIn)).Trim()
  $wOut = (& wsl.exe -d $WslDistro -e wslpath -a (To-Slash $jsonOut)).Trim()
  Invoke-Native 'wsl.exe' @('-d', $WslDistro, '-e', 'python3', '-I', $wPre, $wIn, $wOut) 'preprocess_openapi.py (WSL)'
}

# --- 3. Paquete de generacion -------------------------------------------------
Step "[3/7] pub get (Dart de $GenFlutter) con tool/api_gen"
Copy-Item (Join-Path $AppRoot 'tool\api_gen\pubspec.yaml') $Work
Copy-Item (Join-Path $AppRoot 'tool\api_gen\pubspec.lock') $Work
Copy-Item (Join-Path $AppRoot 'swagger_parser.yaml') $Work
Push-Location $Work
try {
  Invoke-Native $GenDart @('pub', 'get', '--enforce-lockfile') 'pub get'

  # --- 4. Generacion ----------------------------------------------------------
  Step '[4/7] swagger_parser + parche MetaSealed? + build_runner'
  Invoke-Native $GenDart @('run', 'swagger_parser') 'swagger_parser'
  # swagger_parser genera `final MetaSealed meta;` con `this.meta` opcional -> no compila.
  Get-ChildItem (Join-Path $Work "$ApiRel\models") -Filter '*.dart' | ForEach-Object {
    $txt = [IO.File]::ReadAllText($_.FullName)
    if ($txt.Contains('final MetaSealed meta;')) {
      [IO.File]::WriteAllText($_.FullName, $txt.Replace('final MetaSealed meta;', 'final MetaSealed? meta;'))
    }
  }
  Invoke-Native $GenDart @('run', 'build_runner', 'build') 'build_runner'
} finally {
  Pop-Location
}

# --- 5. Formato con el Dart del proyecto -------------------------------------
Step "[5/7] dart format (Dart de $ProjectFlutter, language 3.8)"
$genApi = Join-Path $Work $ApiRel
& $FmtDart format --language-version=3.8 $genApi | Select-Object -Last 1
if ($LASTEXITCODE -ne 0) { Fail "dart format fallo (exit $LASTEXITCODE)" }

# --- 6. Renumeracion de DataN -------------------------------------------------
Step '[6/7] Revisando tipos anonimos DataN'
function Get-DataSignatures([string]$modelsDir) {
  $map = @{}
  if (-not (Test-Path $modelsDir)) { return $map }
  Get-ChildItem $modelsDir -Filter 'data*.dart' | Where-Object { $_.Name -match '^data\d+\.dart$' } | ForEach-Object {
    $src = [IO.File]::ReadAllText($_.FullName)
    $m = [regex]::Match($src, 'class (Data\d+)\b')
    if (-not $m.Success) { return }
    $fields = [regex]::Matches($src, '(?m)^\s*final ([^;=]+?) (\w+);') | ForEach-Object { "$($_.Groups[1].Value) $($_.Groups[2].Value)" }
    $map[$m.Groups[1].Value] = (($fields | Sort-Object) -join '; ')
  }
  return $map
}
$old = Get-DataSignatures (Join-Path $ProjectApi 'models')
$new = Get-DataSignatures (Join-Path $genApi 'models')
$changed = @()
foreach ($name in (@($old.Keys) + @($new.Keys) | Sort-Object -Unique)) {
  $o = if ($old.ContainsKey($name)) { $old[$name] } else { $null }
  $n = if ($new.ContainsKey($name)) { $new[$name] } else { $null }
  if ($o -ne $n) { $changed += $name }
}
if ($changed.Count -eq 0) {
  Write-Host "    Sin cambios en DataN ($($new.Count) tipos)." -ForegroundColor Green
} else {
  Write-Host "    AVISO: cambio la numeracion/contenido de: $($changed -join ', ')" -ForegroundColor Yellow
  foreach ($name in $changed) {
    if (-not $old.ContainsKey($name)) { continue }
    $target = @($new.Keys | Where-Object { $new[$_] -eq $old[$name] })
    $hint = if ($target.Count -gt 0) { "ahora es $($target -join ' / ')" } else { 'sin equivalente exacto (cambiaron los campos)' }
    Write-Host "      $name { $($old[$name]) } -> $hint"
  }
  # Referencias de la app/tests a los DataN afectados (hay que renombrarlas a mano).
  $pattern = '\b(' + ($changed -join '|') + ')\b|models/(' + (($changed | ForEach-Object { $_.ToLower() }) -join '|') + ')\.dart'
  $refs = Get-ChildItem (Join-Path $AppRoot 'lib'), (Join-Path $AppRoot 'test') -Recurse -Filter '*.dart' |
    Where-Object { -not $_.FullName.StartsWith($ProjectApi + '\') } |
    Select-String -Pattern $pattern
  if ($refs) {
    Write-Host '    Referencias fuera de lib/core/api a revisar:' -ForegroundColor Yellow
    $refs | ForEach-Object { Write-Host ("      {0}:{1}: {2}" -f $_.Path.Substring($AppRoot.Length + 1), $_.LineNumber, $_.Line.Trim()) }
  } else {
    Write-Host '    Ninguna referencia fuera de lib/core/api usa esos DataN.'
  }
}

# --- 7. Resultado -------------------------------------------------------------
if ($Apply) {
  Step '[7/7] Aplicando al proyecto: lib/core/api/ y openapi/v1.{yaml,json}'
  Remove-Item -Recurse -Force $ProjectApi
  Copy-Item -Recurse $genApi $ProjectApi
  Copy-Item (Join-Path $Work 'openapi\v1.yaml') (Join-Path $AppRoot 'openapi\v1.yaml') -Force
  Copy-Item (Join-Path $Work 'openapi\v1.json') (Join-Path $AppRoot 'openapi\v1.json') -Force
  Write-Host 'Listo. Siguiente: C:\flutter\bin\flutter.bat analyze y flutter test.'
  if (-not $KeepWork) { Remove-Item -Recurse -Force $Work }
} else {
  $dest = Join-Path $Out $ApiRel
  Step "[7/7] Copiando resultado a $dest (el proyecto no se toca)"
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
  Copy-Item -Recurse $genApi $dest
  Write-Host 'Diff contra lib/core/api del proyecto:'
  & git -C $AppRoot diff --no-index --stat -- (To-Slash $ProjectApi) (To-Slash $dest)
  if ($LASTEXITCODE -eq 0) {
    Write-Host '    IDENTICO al lib/core/api actual.' -ForegroundColor Green
  } else {
    Write-Host "    HAY DIFERENCIAS (detalle: git diff --no-index `"$ProjectApi`" `"$dest`")" -ForegroundColor Yellow
  }
}
