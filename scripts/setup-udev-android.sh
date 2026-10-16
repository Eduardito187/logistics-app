#!/usr/bin/env bash
# Crea la regla udev para que adb (como tu usuario) pueda abrir teléfonos Android
# por USB dentro de WSL (tras pasarlos con usbipd). Correr UNA sola vez:
#
#   sudo scripts/setup-udev-android.sh
#
# Después: adb kill-server && adb start-server && adb devices
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Corré con sudo:  sudo $0" >&2
  exit 1
fi

RULES=/etc/udev/rules.d/51-android.rules
# OJO: udev NO permite comentarios al final de una línea de regla (invalida la línea).
# Los comentarios van en su propia línea. Vendors: 22d9 OnePlus/OPPO, 18d1 Google,
# 04e8 Samsung, 2717 Xiaomi, 22b8 Motorola, 12d1 Huawei.
cat > "$RULES" <<'EOF'
# Android ADB por USB (adb accesible sin root).
SUBSYSTEM=="usb", ATTR{idVendor}=="22d9", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2717", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", MODE="0666", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="12d1", MODE="0666", GROUP="plugdev"
EOF

udevadm control --reload-rules
udevadm trigger
# En WSL a veces el servicio udev no está activo; lo intentamos sin fallar.
service udev restart >/dev/null 2>&1 || true
udevadm trigger >/dev/null 2>&1 || true

echo "✓ Regla udev instalada en $RULES"
echo "Ahora: adb kill-server && adb start-server && adb devices"
echo "(el teléfono debería pasar de 'no permissions' a 'unauthorized' -> aceptá el diálogo en la pantalla)"
