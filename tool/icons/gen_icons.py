"""Genera los íconos DisTrack de la app a partir de los SVG fuente.

    pip install svgelements
    python tool/icons/gen_icons.py

Entradas:
  tool/icons/catalog.json   cada AppIcon: nombre, Icons.* de Material que reemplaza, etiqueta, lote.
  tool/icons/svg/<name>.svg dibujo del ícono (grilla 24×24). Ver tool/icons/README.md.

Salidas (no editar a mano):
  lib/core/icons/generated/app_icon.g.dart         enum AppIcon (fallback Material + etiqueta).
  lib/core/icons/generated/app_icon_glyphs.g.dart  formas como comandos constantes.
"""
import json
import os
import re
import sys

from svgelements import (SVG, Arc, Close, CubicBezier, Line, Move, Path,
                         QuadraticBezier, Shape)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
OUT = os.path.join(ROOT, 'lib', 'core', 'icons', 'generated')
HEADER = ('// GENERADO por tool/icons/gen_icons.py desde tool/icons/catalog.json y tool/icons/svg/.\n'
          '// NO editar a mano: cambiar el SVG/catálogo y regenerar.\n')


def n(v):
    s = f'{v:.3f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def cmds_of(shape):
    path = Path(shape) if not isinstance(shape, Path) else shape
    path = path.reify() if hasattr(path, 'reify') else path
    out = []
    for seg in path:
        if isinstance(seg, Move):
            out += [0, seg.end.x, seg.end.y]
        elif isinstance(seg, Line):
            out += [1, seg.end.x, seg.end.y]
        elif isinstance(seg, Close):
            out += [3]
        elif isinstance(seg, CubicBezier):
            out += [2, seg.control1.x, seg.control1.y, seg.control2.x, seg.control2.y, seg.end.x, seg.end.y]
        elif isinstance(seg, QuadraticBezier):
            p0, q, p = seg.start, seg.control, seg.end
            out += [2, p0.x + 2 / 3 * (q.x - p0.x), p0.y + 2 / 3 * (q.y - p0.y),
                    p.x + 2 / 3 * (q.x - p.x), p.y + 2 / 3 * (q.y - p.y), p.x, p.y]
        elif isinstance(seg, Arc):
            for c in seg.as_cubic_curves():
                out += [2, c.control1.x, c.control1.y, c.control2.x, c.control2.y, c.end.x, c.end.y]
        else:
            raise ValueError(f'segmento no soportado: {type(seg).__name__}')
    return out


def parse_svg(path):
    raw = open(path, encoding='utf-8').read()
    if re.search(r'https?://(?!www\.w3\.org/2000/svg)', raw):
        raise ValueError('el SVG referencia una URL externa')
    svg = SVG.parse(path, reify=True)
    parts = []
    for el in svg.elements():
        if not isinstance(el, Shape):
            continue
        attrs = el.values
        classes = str(attrs.get('class', '')).split()
        fill = str(attrs.get('fill', 'none')).lower() not in ('none', '', 'transparent')
        stroke_none = str(attrs.get('stroke', '')).lower() == 'none'
        cmds = cmds_of(el)
        if not cmds:
            continue
        parts.append({
            'cmds': cmds,
            'fill': fill or stroke_none,
            'accent': 'ds-accent' in classes,
            'opacity': float(attrs.get('opacity', 1) or 1),
            'tags': [c[5:] for c in classes if c.startswith('ds-p-')],
        })
    return parts


def dart_part(p):
    args = ['cmds: [' + ', '.join(n(v) for v in p['cmds']) + ']']
    if p['fill']:
        args.append('fill: true')
    if p['accent']:
        args.append('accent: true')
    if p['opacity'] != 1:
        args.append(f"opacity: {n(p['opacity'])}")
    if p['tags']:
        args.append('tags: [' + ', '.join(f"'{t}'" for t in p['tags']) + ']')
    return 'GlyphPart(' + ', '.join(args) + ')'


def main():
    catalog = json.load(open(os.path.join(HERE, 'catalog.json'), encoding='utf-8'))
    os.makedirs(OUT, exist_ok=True)

    # enum AppIcon
    lines = [HEADER, "import 'package:flutter/material.dart';\n",
             '/// Íconos custom DisTrack de la app. Cada uno reemplaza a uno o más `Icons.*`',
             '/// de Material ([fallback] es el primero, usado si faltara el dibujo).',
             'enum AppIcon {']
    for i, c in enumerate(catalog):
        fb = c['materials'][0] if c['materials'] else 'circle_outlined'
        mats = ', '.join(c['materials']) or '—'
        end = ';' if i == len(catalog) - 1 else ','
        lines.append(f"  /// {c['label']} · lote {c['lot']} · reemplaza: {mats}")
        lines.append(f"  {c['name']}(Icons.{fb}, '{c['label']}'){end}")
    lines += ['', '  const AppIcon(this.fallback, this.label);', '',
              '  /// Ícono Material equivalente (fallback mientras no exista el dibujo).',
              '  final IconData fallback;', '',
              '  /// Etiqueta en español para lectores de pantalla.',
              '  final String label;', '}', '']
    open(os.path.join(OUT, 'app_icon.g.dart'), 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))

    # Glifos
    glyphs, missing, errors = [], [], []
    for c in catalog:
        svg_path = os.path.join(HERE, 'svg', c['name'] + '.svg')
        if not os.path.exists(svg_path):
            missing.append(c['name'])
            continue
        try:
            parts = parse_svg(svg_path)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{c['name']}: {e}")
            continue
        body = ',\n    '.join(dart_part(p) for p in parts)
        glyphs.append(f"  AppIcon.{c['name']}: IconGlyph([\n    {body},\n  ]),")
    g = [HEADER, "import '../icon_glyph.dart';", "import 'app_icon.g.dart';", '',
         '/// Dibujo de cada [AppIcon] (grilla 24×24).',
         'const Map<AppIcon, IconGlyph> kAppIconGlyphs = {', *glyphs, '};', '']
    open(os.path.join(OUT, 'app_icon_glyphs.g.dart'), 'w', encoding='utf-8', newline='\n').write('\n'.join(g))

    print(f'{len(catalog)} AppIcon · {len(glyphs)} con dibujo · faltan {len(missing)}: {missing}')
    if errors:
        print('ERRORES:\n  ' + '\n  '.join(errors))
        sys.exit(1)


if __name__ == '__main__':
    main()
