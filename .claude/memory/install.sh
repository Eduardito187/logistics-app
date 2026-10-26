#!/usr/bin/env bash
# Instala (o re-exporta) las memorias del proyecto desde/hacia el espejo versionado.
#
# Las memorias de Claude Code viven FUERA del repo, en:
#   ~/.claude/projects/<slug>/memory/
# donde <slug> = ruta absoluta del proyecto con los separadores vueltos '-'.
# Este espejo (.claude/memory/) viaja con git; el script lo sincroniza con el
# dir del usuario en CUALQUIER máquina/ruta, calculando el slug solo.
#
# Uso:
#   bash .claude/memory/install.sh            # repo  -> dir del usuario (default)
#   bash .claude/memory/install.sh --export   # dir del usuario -> repo (para versionar cambios)
set -euo pipefail

# Raíz del repo = carpeta padre de este script (.claude/memory/ -> .claude -> repo).
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

# Slug: ruta absoluta con '/' , '\' y ':' -> '-'  (p. ej. /dismac/logistics-app -> -dismac-logistics-app)
slug="$(printf '%s' "$repo_root" | sed -e 's#[/\\:]#-#g')"
user_dir="${HOME}/.claude/projects/${slug}/memory"

if [[ "${1:-}" == "--export" ]]; then
  src="$user_dir"; dst="$script_dir"
  echo "Exportando memorias del usuario -> espejo del repo"
else
  src="$script_dir"; dst="$user_dir"
  echo "Instalando memorias del repo -> dir del usuario"
fi

mkdir -p "$dst"
# Copia solo los .md (no el propio script).
found=0
for f in "$src"/*.md; do
  [[ -e "$f" ]] || continue
  cp -f "$f" "$dst/"
  found=1
done
[[ "$found" == 1 ]] || { echo "No hay .md en $src"; exit 1; }
echo "Listo. Ruta del proyecto: $repo_root"
echo "Slug:                    $slug"
echo "Dir de memorias:         $user_dir"
