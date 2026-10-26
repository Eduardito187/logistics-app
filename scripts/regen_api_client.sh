#!/usr/bin/env bash
# Regenera el cliente Dart del API (lib/core/api/) desde openapi/v1.yaml del backend.
# Regla #5 de CLAUDE.md: los DTOs del API no se escriben a mano, salen de aqui.
# Equivalente a scripts/regen_api_client.ps1 (ver docs/cliente-api.md).
#
# Funciona en Windows (Git Bash) y en Linux/WSL. Todo se genera en una carpeta
# temporal con el pubspec MINIMO de tool/api_gen/ (Dart >= 3.13: retrofit_generator
# ^10.2.12 no corre en el Dart 3.8 del proyecto) y solo al final se copia lib/core/api.
#
# Uso:
#   scripts/regen_api_client.sh [--spec <v1.yaml>] [--out <dir> | --dry-run] [--keep]
#     --spec     spec del backend (default: repo backend en WSL)
#     --out      deja el resultado en <dir>/lib/core/api y no toca el proyecto
#     --dry-run  igual que --out a una carpeta temporal + diff contra el proyecto
#
# Variables opcionales:
#   GEN_DART  Dart para generar (Windows: /c/sdk/flutter/bin/dart; Linux: ~/sdk/flutter/bin/dart)
#   FMT_DART  Dart para formatear = el del proyecto (Windows: /c/flutter/bin/dart)
#   WSL_DISTRO  distro con python3+PyYAML si no hay PyYAML local (default Ubuntu-22.04)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
API_REL="lib/core/api"

IS_WINDOWS=0
case "$(uname -s)" in MINGW* | MSYS* | CYGWIN*) IS_WINDOWS=1 ;; esac

if [[ $IS_WINDOWS -eq 1 ]]; then
  SPEC_DEFAULT='//wsl.localhost/Ubuntu-22.04/dismac/logistics/openapi/v1.yaml'
  GEN_DART="${GEN_DART:-/c/sdk/flutter/bin/dart}"
  FMT_DART="${FMT_DART:-/c/flutter/bin/dart}"
  WORK_BASE="$(cygpath -u "${LOCALAPPDATA}")/Temp/logistics-api-gen"
else
  SPEC_DEFAULT='/dismac/logistics/openapi/v1.yaml'
  GEN_DART="${GEN_DART:-$HOME/sdk/flutter/bin/dart}"
  FMT_DART="${FMT_DART:-$GEN_DART}"
  WORK_BASE="${TMPDIR:-/tmp}/logistics-api-gen"
fi
WSL_DISTRO="${WSL_DISTRO:-Ubuntu-22.04}"

SPEC="$SPEC_DEFAULT"
OUT=""
DRY_RUN=0
KEEP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec) SPEC="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --keep) KEEP=1; shift ;;
    -h | --help) sed -n '2,20p' "$0"; exit 0 ;;
    -*) echo "Opcion desconocida: $1" >&2; exit 2 ;;
    *) SPEC="$1"; shift ;; # compatibilidad: primer argumento posicional = spec
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
[[ -f "$SPEC" ]] || die "no se encontro el spec del backend: $SPEC (usa --spec)"
[[ -x "$GEN_DART" || -f "$GEN_DART" ]] || die "no esta el Dart de generacion: $GEN_DART (GEN_DART)"
[[ -x "$FMT_DART" || -f "$FMT_DART" ]] || die "no esta el Dart del proyecto: $FMT_DART (FMT_DART)"

WORK="$WORK_BASE/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$WORK/openapi"
echo "Carpeta de trabajo: $WORK"

APPLY=0
if [[ $DRY_RUN -eq 0 && -z "$OUT" ]]; then APPLY=1; fi
if [[ $DRY_RUN -eq 1 && -z "$OUT" ]]; then OUT="$WORK/out"; fi

echo "==> [1/7] Copiando spec: $SPEC"
cp "$SPEC" "$WORK/openapi/v1.yaml"

echo "==> [2/7] Preprocesando YAML -> JSON"
PY=""
for cand in python3 python py; do
  if command -v "$cand" > /dev/null 2>&1 && "$cand" -I -c 'import yaml' > /dev/null 2>&1; then
    PY="$cand"; break
  fi
done
if [[ -n "$PY" ]]; then
  echo "    $PY local con PyYAML"
  "$PY" -I "$SCRIPT_DIR/preprocess_openapi.py" "$WORK/openapi/v1.yaml" "$WORK/openapi/v1.json"
elif [[ $IS_WINDOWS -eq 1 ]]; then
  echo "    sin PyYAML local -> python3 de WSL ($WSL_DISTRO)"
  to_wsl() { MSYS_NO_PATHCONV=1 wsl.exe -d "$WSL_DISTRO" -e wslpath -a "$(cygpath -m "$1")" | tr -d '\r'; }
  MSYS_NO_PATHCONV=1 wsl.exe -d "$WSL_DISTRO" -e python3 -I \
    "$(to_wsl "$SCRIPT_DIR/preprocess_openapi.py")" \
    "$(to_wsl "$WORK/openapi/v1.yaml")" "$(to_wsl "$WORK/openapi/v1.json")"
else
  die "falta PyYAML (pip install pyyaml / apt install python3-yaml)"
fi

echo "==> [3/7] pub get con tool/api_gen ($GEN_DART)"
cp "$APP_ROOT/tool/api_gen/pubspec.yaml" "$APP_ROOT/tool/api_gen/pubspec.lock" \
  "$APP_ROOT/swagger_parser.yaml" "$WORK/"
cd "$WORK"
"$GEN_DART" pub get --enforce-lockfile

echo "==> [4/7] swagger_parser + parche MetaSealed? + build_runner"
"$GEN_DART" run swagger_parser
# swagger_parser genera `final MetaSealed meta;` con `this.meta` opcional -> no compila.
grep -rl "final MetaSealed meta;" "$WORK/$API_REL/models/" 2> /dev/null \
  | xargs -r sed -i 's/final MetaSealed meta;/final MetaSealed? meta;/' || true
"$GEN_DART" run build_runner build

echo "==> [5/7] dart format ($FMT_DART, language 3.8)"
"$FMT_DART" format --language-version=3.8 "$WORK/$API_REL" | tail -n 1

echo "==> [6/7] Revisando tipos anonimos DataN"
# Firma de cada DataN = sus campos `final Tipo nombre;` ordenados.
signatures() {
  local dir="$1" f name
  [[ -d "$dir" ]] || return 0
  for f in "$dir"/data[0-9]*.dart; do
    [[ "$f" == *.g.dart ]] && continue
    name="$(grep -oE 'class Data[0-9]+' "$f" | head -n 1 | cut -d' ' -f2)"
    [[ -n "$name" ]] || continue
    printf '%s|%s\n' "$name" \
      "$(grep -E '^\s*final [^;=]+ \w+;' "$f" | sed -E 's/^\s*final //; s/;$//' | sort | paste -sd ';' -)"
  done | sort
}
signatures "$APP_ROOT/$API_REL/models" > "$WORK/data_old.txt"
signatures "$WORK/$API_REL/models" > "$WORK/data_new.txt"
CHANGED="$(diff "$WORK/data_old.txt" "$WORK/data_new.txt" | grep -E '^[<>]' | cut -c3- | cut -d'|' -f1 | sort -u || true)"
if [[ -z "$CHANGED" ]]; then
  echo "    Sin cambios en DataN ($(wc -l < "$WORK/data_new.txt") tipos)."
else
  echo "    AVISO: cambio la numeracion/contenido de: $(echo $CHANGED)"
  while IFS='|' read -r name sig; do
    grep -qx "$name" <<< "$CHANGED" || continue
    target="$(awk -F'|' -v s="$sig" '$2==s{print $1}' "$WORK/data_new.txt" | paste -sd '/' -)"
    echo "      $name { $sig } -> ${target:-sin equivalente exacto (cambiaron los campos)}"
  done < "$WORK/data_old.txt"
  names="$(echo $CHANGED | tr ' ' '|')"
  lower="$(echo "$names" | tr 'A-Z' 'a-z')"
  refs="$(cd "$APP_ROOT" && grep -rnE "\b($names)\b|models/($lower)\.dart" lib test --include='*.dart' \
    | grep -v "^$API_REL/" || true)"
  if [[ -n "$refs" ]]; then
    echo "    Referencias fuera de $API_REL a revisar:"
    echo "$refs" | sed 's/^/      /'
  else
    echo "    Ninguna referencia fuera de $API_REL usa esos DataN."
  fi
fi

if [[ $APPLY -eq 1 ]]; then
  echo "==> [7/7] Aplicando al proyecto: $API_REL/ y openapi/v1.{yaml,json}"
  rm -rf "${APP_ROOT:?}/$API_REL"
  cp -r "$WORK/$API_REL" "$APP_ROOT/$API_REL"
  cp "$WORK/openapi/v1.yaml" "$WORK/openapi/v1.json" "$APP_ROOT/openapi/"
  echo "Listo. Siguiente: flutter analyze y flutter test (con el Flutter del proyecto)."
  [[ $KEEP -eq 1 ]] || rm -rf "$WORK"
else
  DEST="$OUT/$API_REL"
  echo "==> [7/7] Copiando resultado a $DEST (el proyecto no se toca)"
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  cp -r "$WORK/$API_REL" "$DEST"
  echo "Diff contra $API_REL del proyecto:"
  if git -C "$APP_ROOT" diff --no-index --stat -- "$APP_ROOT/$API_REL" "$DEST"; then
    echo "    IDENTICO al $API_REL actual."
  else
    echo "    HAY DIFERENCIAS (detalle: git diff --no-index \"$APP_ROOT/$API_REL\" \"$DEST\")"
  fi
fi
