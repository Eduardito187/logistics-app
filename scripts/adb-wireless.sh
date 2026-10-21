#!/usr/bin/env bash
# DisTrack — ADB inalámbrico desde WSL (Linux). VS Code en Remote-WSL usa el
# Flutter de WSL, así que el teléfono debe estar en el adb de WSL (este).
#
# La clave ~/.android/adbkey se copió desde Windows, así que el teléfono YA
# confía en este adb (no hace falta re-vincular).
#
# Uso:
#   ./scripts/adb-wireless.sh connect 192.168.1.42:5555   # conecta y lo recuerda
#   ./scripts/adb-wireless.sh reconnect                   # reconecta al último (def. 192.168.1.42:5555)
#   ./scripts/adb-wireless.sh usb                         # con cable: tcpip 5555 + connect (5555 estable)
#   ./scripts/adb-wireless.sh mdns                        # autodescubre por mDNS (openscreen)
set -euo pipefail

ADB="${ADB:-$HOME/Android/Sdk/platform-tools/adb}"
export ADB_MDNS_OPENSCREEN=1
LAST="$HOME/.distrack-adb-last"
DEFAULT="192.168.1.42:5555"

connect() {
  local t="$1"
  echo "Conectando (WSL) a $t ..."
  "$ADB" connect "$t" || true
  "$ADB" devices -l
  printf '%s' "$t" > "$LAST"
  echo "Guardado como último destino ($t). La próxima: reconnect."
}

"$ADB" start-server >/dev/null 2>&1 || true

case "${1:-}" in
  connect)   connect "${2:?Falta ip:puerto}";;
  reconnect) connect "$([ -f "$LAST" ] && cat "$LAST" || echo "$DEFAULT")";;
  mdns)      "$ADB" kill-server || true; "$ADB" start-server; sleep 3; "$ADB" mdns services; "$ADB" devices -l;;
  usb)
    echo "Esperando teléfono por USB (debe estar atado a WSL con usbipd)..."
    "$ADB" wait-for-device
    "$ADB" tcpip 5555; sleep 2
    ip=$("$ADB" shell ip -f inet addr show wlan0 2>/dev/null | grep -oE 'inet [0-9.]+' | awk '{print $2}' | head -1)
    [ -n "$ip" ] || { echo "No pude leer la IP WiFi; usá: connect <ip>:5555"; exit 1; }
    connect "$ip:5555"
    echo "LISTO: desenchufá el cable. Queda en $ip:5555 hasta reiniciar el teléfono."
    ;;
  *) echo "Uso: $0 {connect <ip:puerto>|reconnect|usb|mdns}"; exit 2;;
esac
