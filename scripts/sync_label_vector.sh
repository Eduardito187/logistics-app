#!/usr/bin/env bash
# Sincroniza el vector de prueba de etiquetas Ed25519 con el del backend.
#
# El vector es compartido logistics <-> logistics-app y debe ser identico byte a byte
# (ver seccion "Etiquetas QR" de CLAUDE.md). Si el backend lo regenera, se copia aca.
#
# Uso:
#   scripts/sync_label_vector.sh [ruta/al/vector/backend.json]
#
# Muestra el diff si el contenido cambio; no falla si son identicos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Origen (backend) y destino (fixture del app).
BACKEND_VECTOR="${1:-/dismac/logistics/packages/logistics/labels/tests/Fixtures/label-test-vector.json}"
APP_VECTOR="$APP_ROOT/test/fixtures/label_test_vector.json"

if [[ ! -f "$BACKEND_VECTOR" ]]; then
  echo "ERROR: no se encontro el vector del backend en: $BACKEND_VECTOR" >&2
  echo "       Pasa la ruta como argumento o clona el repo backend en /dismac/logistics." >&2
  exit 1
fi

# Si ya existe y es identico, no hay nada que hacer.
if [[ -f "$APP_VECTOR" ]] && diff -q "$BACKEND_VECTOR" "$APP_VECTOR" >/dev/null; then
  echo "==> El vector ya esta sincronizado (sin cambios): $APP_VECTOR"
  exit 0
fi

# Hay diferencia (o el destino no existe): mostramos el diff antes de copiar.
if [[ -f "$APP_VECTOR" ]]; then
  echo "==> El vector cambio. Diferencias (backend vs app):"
  diff "$APP_VECTOR" "$BACKEND_VECTOR" || true
else
  echo "==> El fixture no existia; se crea desde el backend."
fi

mkdir -p "$(dirname "$APP_VECTOR")"
cp "$BACKEND_VECTOR" "$APP_VECTOR"
echo "==> Vector sincronizado: $BACKEND_VECTOR -> $APP_VECTOR"
echo "    Revisa el cambio y corre 'flutter test' para validar la verificacion Ed25519."
