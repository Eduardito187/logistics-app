"""Codemod: migra `Icon(Icons.x, …)` a `AnimatedAppIcon(AppIcon.y, …)` según tool/icons/catalog.json.

    python3 tool/icons/migrate_icons.py lib/features/driver [más rutas…]

- Reemplaza cada llamada `Icon(` cuyo primer argumento usa `Icons.*` (también ternarios) por
  `AnimatedAppIcon(` con el AppIcon equivalente. Los parámetros de Icon (size, color, semanticLabel)
  tienen el mismo nombre en AnimatedAppIcon.
- Agrega el import relativo a lib/core/icons/icons.dart donde haga falta.
- NO toca los `Icons.*` usados como dato (p. ej. `icon: Icons.x` de RoleTask o de widgets propios que
  reciben IconData): los lista al final para migrarlos a mano (cambiar el parámetro a AppIcon, o
  agregar `appIcon:` en RoleTask).
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
CATALOG = json.load(open(os.path.join(HERE, 'catalog.json'), encoding='utf-8'))
MAP = {m: c['name'] for c in CATALOG for m in c['materials']}
ICONS_LIB = os.path.join(ROOT, 'lib', 'core', 'icons', 'icons.dart')


def first_arg_end(src, start):
    """Índice donde termina el primer argumento de la llamada que abre en `start` ('(')."""
    depth = 0
    i = start
    while i < len(src):
        ch = src[i]
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
            if depth == 0:
                return i
        elif ch == ',' and depth == 1:
            return i
        elif ch in '\'"':
            q = ch
            i += 1
            while i < len(src) and src[i] != q:
                i += 2 if src[i] == '\\' else 1
        i += 1
    return -1


def migrate(src, unknown):
    out, pos = [], 0
    for m in re.finditer(r'(?<![\w.])Icon\(', src):
        if m.start() < pos:
            continue
        open_paren = m.end() - 1
        end = first_arg_end(src, open_paren)
        arg = src[open_paren + 1:end]
        if 'Icons.' not in arg:
            continue

        def sub(mm):
            name = MAP.get(mm.group(1))
            if name is None:
                unknown.add(mm.group(1))
                return mm.group(0)
            return 'AppIcon.' + name

        new_arg = re.sub(r'\bIcons\.([a-z_0-9]+)', sub, arg)
        if 'Icons.' in new_arg:
            continue
        out.append(src[pos:m.start()])
        out.append('AnimatedAppIcon(' + new_arg)
        pos = end
    out.append(src[pos:])
    return ''.join(out)


def ensure_import(path, src):
    if 'AppIcon' not in src or re.search(r"import '[^']*core/icons/icons.dart'", src) or "import '../icons/icons.dart'" in src or "import 'icons/icons.dart'" in src:
        return src
    rel = os.path.relpath(ICONS_LIB, os.path.dirname(path)).replace(os.sep, '/')
    line = f"import '{rel}';\n"
    imports = list(re.finditer(r"^import '\.[^']*';\n", src, re.M))
    if imports:
        # Insertar en orden alfabético entre los imports relativos.
        for im in imports:
            if im.group(0) > line:
                return src[:im.start()] + line + src[im.start():]
        last = imports[-1]
        return src[:last.end()] + line + src[last.end():]
    pkg = list(re.finditer(r"^import 'package:[^']*';\n", src, re.M))
    at = pkg[-1].end() if pkg else 0
    return src[:at] + '\n' + line + src[at:]


def main():
    targets = sys.argv[1:] or ['lib']
    files = []
    for t in targets:
        t = os.path.join(ROOT, t) if not os.path.isabs(t) else t
        if os.path.isfile(t):
            files.append(t)
        for dp, _, fn in os.walk(t):
            files += [os.path.join(dp, f) for f in fn if f.endswith('.dart') and not f.endswith('.g.dart')]
    unknown, changed, leftovers = set(), 0, []
    for f in sorted(set(files)):
        raw = open(f, encoding='utf-8', newline='').read()
        crlf = '\r\n' in raw
        src = raw.replace('\r\n', '\n')
        new = ensure_import(f, migrate(src, unknown))
        if new != src:
            # Conserva el fin de línea del archivo (el repo mezcla CRLF y LF).
            out = new.replace('\n', '\r\n') if crlf else new
            open(f, 'w', encoding='utf-8', newline='').write(out)
            changed += 1
        for i, line in enumerate(new.split('\n'), 1):
            if 'Icons.' in line:
                leftovers.append(f'{os.path.relpath(f, ROOT)}:{i}: {line.strip()}')
    print(f'{changed} archivos migrados')
    if unknown:
        print('Icons.* sin AppIcon en el catálogo:', sorted(unknown))
    if leftovers:
        print(f'{len(leftovers)} Icons.* restantes (migrar a mano):')
        print('\n'.join('  ' + l for l in leftovers))


if __name__ == '__main__':
    main()
