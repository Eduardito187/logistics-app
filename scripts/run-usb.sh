#!/usr/bin/env bash
# Compila y corre la app en un teléfono Android por USB, desde WSL, usando usbipd.
#
# Uso:   scripts/run-usb.sh [dev|staging|production]   (por defecto: dev)
#
# Requisitos una sola vez:
#   1) usbipd-win instalado en Windows (ya está).
#   2) El teléfono "bound" en usbipd (con admin):  usbipd bind --busid <id>
#   3) Regla udev para permisos:  sudo scripts/setup-udev-android.sh
#   4) En el teléfono: Depuración USB activada + modo USB "Transferencia de archivos".
#
# Cada vez: enchufás el teléfono y corrés este script. Pasa el USB a WSL y lanza flutter.
set -euo pipefail

ENV="${1:-dev}"
CONFIG="config/${ENV}.json"
cd "$(dirname "$0")/.."
[ -f "$CONFIG" ] || { echo "ERROR: no existe $CONFIG (envs: dev|staging|production)"; exit 1; }

export PATH="$HOME/sdk/flutter/bin:$HOME/jdk/bin:$HOME/Android/Sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk" JAVA_HOME="$HOME/jdk"
unset ADB_SERVER_SOCKET 2>/dev/null || true

USBIPD="/mnt/c/Program Files/usbipd-win/usbipd.exe"
WADB="/mnt/c/Users/ehhuallata/AppData/Local/Android/Sdk/platform-tools/adb.exe"

# 1) Pasar el teléfono a WSL si todavía no está presente.
if ! lsusb 2>/dev/null | grep -qiE "22d9|oneplus"; then
  echo "==> Pasando el teléfono a WSL (usbipd attach)..."
  "$WADB" kill-server >/dev/null 2>&1 || true   # soltar el adb de Windows que lo retiene
  BUSID=$("$USBIPD" list 2>/dev/null | sed 's/\r//g' | awk '/22d9|OnePlus/{print $1; exit}')
  if [ -n "$BUSID" ]; then
    "$USBIPD" attach --wsl --busid "$BUSID" 2>&1 | sed 's/\r//g' || true
  else
    echo "   No encontré el teléfono en usbipd. Enchufalo y poné el USB en 'Transferencia de archivos'."
  fi
  sleep 3
fi

# 2) adb local de WSL.
echo "==> Buscando el teléfono en adb..."
adb start-server >/dev/null 2>&1 || true
for i in $(seq 1 30); do
  line=$(adb devices | sed 's/\r//g' | awk 'NR>1 && NF>=2{print; exit}')
  case "$line" in
    *device) break ;;
    *unauthorized*) echo "   -> Aceptá '¿Permitir depuración USB?' en la pantalla del teléfono (Permitir siempre)." ;;
    *"no permissions"*) echo "   -> Permisos: corré una vez  sudo scripts/setup-udev-android.sh  (y reconectá)." ;;
  esac
  sleep 2
done

DEVICE=$(adb devices | sed 's/\r//g' | awk 'NR>1 && $2=="device"{print $1; exit}')
if [ -z "$DEVICE" ]; then
  echo "ERROR: no hay teléfono autorizado. Estado actual:"
  adb devices -l 2>&1 | sed 's/\r//g'
  exit 1
fi

MODEL="$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || true)"
echo "==> Teléfono: $DEVICE ${MODEL:+($MODEL)}  |  entorno: $ENV"
exec flutter run -d "$DEVICE" --dart-define-from-file="$CONFIG"
