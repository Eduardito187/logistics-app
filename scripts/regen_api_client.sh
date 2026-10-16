#!/usr/bin/env bash
# Regenera el cliente Dart del API desde el contrato OpenAPI del backend.
# Regla #5 de CLAUDE.md: los DTOs del API no se escriben a mano, salen de aqui.
#
# Pasos (reproducen el flujo manual ya validado):
#   1. Copiar openapi/v1.yaml del backend a openapi/v1.yaml del app.
#   2. Preprocesar a openapi/v1.json (anchors + parameters de nivel path).
#   3. dart run swagger_parser          (config en swagger_parser.yaml).
#   4. dart run build_runner build --delete-conflicting-outputs.
#
# Uso:
#   scripts/regen_api_client.sh [ruta/al/spec/backend/v1.yaml]
#
# Idempotente: correrlo de nuevo regenera los mismos artefactos.
set -euo pipefail

# Flutter de WSL en el PATH (regla de entorno del proyecto).
export PATH="$HOME/sdk/flutter/bin:$PATH"

# Raiz del app = carpeta padre de este script, sin importar desde donde se llame.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ruta del spec del backend (argumento opcional, con default).
BACKEND_SPEC="${1:-/dismac/logistics/openapi/v1.yaml}"

APP_SPEC_YAML="$APP_ROOT/openapi/v1.yaml"
APP_SPEC_JSON="$APP_ROOT/openapi/v1.json"

if [[ ! -f "$BACKEND_SPEC" ]]; then
  echo "ERROR: no se encontro el spec del backend en: $BACKEND_SPEC" >&2
  echo "       Pasa la ruta como argumento o clona el repo backend en /dismac/logistics." >&2
  exit 1
fi

cd "$APP_ROOT"

# Paso 1: copiar el contrato del backend.
echo "==> [1/4] Copiando spec del backend: $BACKEND_SPEC -> openapi/v1.yaml"
mkdir -p "$APP_ROOT/openapi"
cp "$BACKEND_SPEC" "$APP_SPEC_YAML"

# Paso 2: preprocesar YAML -> JSON (interprete aislado por seguridad).
echo "==> [2/4] Preprocesando OpenAPI -> openapi/v1.json"
python3 -I "$SCRIPT_DIR/preprocess_openapi.py" "$APP_SPEC_YAML" "$APP_SPEC_JSON"

# Paso 3: generar el cliente con swagger_parser.
echo "==> [3/4] dart run swagger_parser"
dart run swagger_parser

# Parche: swagger_parser genera `final MetaSealed meta;` (no-nullable) con el
# constructor `this.meta` opcional → no compila. Lo volvemos nullable. El fix de
# fondo va en el backend (openapi); mientras tanto este sed lo mantiene durable.
echo "==> parche meta nullable en modelos generados"
grep -rl "final MetaSealed meta;" "$APP_ROOT/lib/core/api/models/" 2>/dev/null \
  | xargs -r sed -i 's/final MetaSealed meta;/final MetaSealed? meta;/'

# Paso 4: generar el codigo de json_serializable.
echo "==> [4/4] dart run build_runner build --delete-conflicting-outputs"
dart run build_runner build --delete-conflicting-outputs

echo "==> Cliente del API regenerado en lib/core/api/"
