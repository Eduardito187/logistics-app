# DisTrack — ADB inalámbrico (WiFi). Atajos para conectar el teléfono sin cable.
#
# El teléfono y la PC deben estar en la MISMA red WiFi. VS Code usa el Flutter
# de Windows (C:/flutter), así que se usa el adb de Windows (el que alimenta la
# lista de dispositivos de VS Code).
#
# Uso (PowerShell, desde la raíz del repo o cualquier lado):
#   .\scripts\adb-wireless.ps1 connect 192.168.1.42:5555   # conecta a ip:puerto y lo recuerda
#   .\scripts\adb-wireless.ps1 reconnect                   # reconecta al último ip:puerto usado
#   .\scripts\adb-wireless.ps1 usb                         # con el cable puesto: pasa a WiFi (5555) y te dice cuándo desenchufar
#   .\scripts\adb-wireless.ps1 pair 192.168.1.42:41234 926551 192.168.1.42:5555
#                                                          # vincula (Android 11+) y conecta; el 3er arg (ip:puerto de conexión) es opcional
param(
  [Parameter(Mandatory = $true)][ValidateSet('mdns', 'connect', 'reconnect', 'usb', 'pair')]
  [string]$Action,
  [string]$Target,
  [string]$Code,
  [string]$ConnectTarget
)
$ErrorActionPreference = 'Stop'

# Backend mDNS "openscreen": descubre el servicio _adb-tls-connect._tcp y
# AUTOCONECTA los teléfonos ya vinculados (lo más confiable con Honor/Magic OS,
# cuyo puerto de conexión rota). Se activa para todas las acciones.
$env:ADB_MDNS_OPENSCREEN = '1'

$adb = 'C:\Users\ehhuallata\AppData\Local\Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) {
  # Respaldo: adb en el PATH.
  $adb = 'adb'
}
$lastFile = Join-Path $env:USERPROFILE '.distrack-adb-last'

function Save-Last([string]$t) { Set-Content -Path $lastFile -Value $t -NoNewline }
function Connect-Target([string]$t) {
  Write-Host "Conectando a $t ..."
  & $adb connect $t
  & $adb devices -l
  Save-Last $t
  Write-Host "Guardado como último destino ($t). La próxima: reconnect."
}

& $adb start-server | Out-Null

switch ($Action) {
  'mdns' {
    # Autoconexión por mDNS: reinicia el server con openscreen y lista. Si el
    # teléfono ya está vinculado y en la misma WiFi, aparece solo.
    & $adb kill-server
    & $adb start-server
    Write-Host "Buscando el teléfono vinculado por WiFi (mDNS)..."
    Start-Sleep -Seconds 3
    & $adb devices -l
  }
  'connect' {
    if (-not $Target) { throw "Falta ip:puerto. Ej: connect 192.168.1.42:5555" }
    Connect-Target $Target
  }
  'reconnect' {
    if (-not (Test-Path $lastFile)) { throw "No hay último destino guardado. Usá: connect <ip:puerto>" }
    Connect-Target (Get-Content -Path $lastFile -Raw).Trim()
  }
  'usb' {
    Write-Host "Buscando teléfono por USB..."
    & $adb wait-for-device
    Write-Host "Pasando el teléfono a modo TCP/IP en el puerto 5555..."
    & $adb tcpip 5555
    Start-Sleep -Seconds 2
    # IP de la WiFi del teléfono (wlan0).
    $ipLine = (& $adb shell ip -f inet addr show wlan0) 2>$null
    $ip = ($ipLine | Select-String -Pattern 'inet (\d+\.\d+\.\d+\.\d+)').Matches.Groups[1].Value
    if (-not $ip) { throw "No pude leer la IP WiFi del teléfono (¿WiFi encendido?). Conectá manual con: connect <ip>:5555" }
    Connect-Target "$($ip):5555"
    Write-Host "LISTO: ya podés DESENCHUFAR el cable. Queda por WiFi en $($ip):5555 hasta reiniciar el teléfono."
  }
  'pair' {
    if (-not $Target -or -not $Code) { throw "Uso: pair <ip:puertoVinculacion> <codigo> [ip:puertoConexion]" }
    Write-Host "Vinculando con $Target ..."
    & $adb pair $Target $Code
    if ($ConnectTarget) {
      Connect-Target $ConnectTarget
    } else {
      Write-Host "Vinculado. Ahora conectá con el puerto de CONEXIÓN (el de la pantalla principal de Depuración inalámbrica):"
      Write-Host "  .\scripts\adb-wireless.ps1 connect <ip:puertoConexion>"
    }
  }
}
