import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Una forma de un ícono DisTrack (un `<path>`, `<circle>`, `<rect>`… del SVG
/// fuente en `tool/icons/svg/`). El generador `tool/icons/gen_icons.py` la
/// convierte a comandos constantes en una grilla de 24×24.
///
/// Comandos en [cmds]: `0 x y` mover · `1 x y` línea · `2 x1 y1 x2 y2 x y`
/// cúbica · `3` cerrar. Los arcos y círculos ya vienen convertidos a cúbicas.
@immutable
class GlyphPart {
  const GlyphPart({
    required this.cmds,
    this.fill = false,
    this.accent = false,
    this.opacity = 1,
    this.tags = const [],
  });

  final List<double> cmds;

  /// Forma rellena (puntos, mosaicos sólidos). Si es `false` se dibuja con trazo.
  final bool fill;

  /// Elemento clave del significado (`class="ds-accent"` en el SVG): remata la
  /// animación con un pop y es el que toma el color de acento.
  final bool accent;

  /// Opacidad propia de la forma (detalles secundarios, p. ej. un anillo tenue).
  final double opacity;

  /// Etiquetas de coreografía (`class="ds-p-<tag>"` en el SVG): permiten mover
  /// piezas sueltas (la caja que cae del camión, el láser del escáner, las
  /// flechas que giran dentro de la nube…). Ver `icon_motion.dart`.
  final List<String> tags;

  bool has(String tag) => tags.contains(tag);
}

/// El dibujo completo de un ícono: sus formas en orden de dibujo.
@immutable
class IconGlyph {
  const IconGlyph(this.parts);

  final List<GlyphPart> parts;
}

final Expando<Path> _paths = Expando<Path>('glyph-path');
final Expando<List<PathMetric>> _metrics = Expando<List<PathMetric>>(
  'glyph-metrics',
);

/// [Path] de la forma en la grilla de 24 (se construye una vez y se cachea).
Path glyphPath(GlyphPart part) => _paths[part] ??= _build(part.cmds);

/// Métricas del trazo (para dibujarlo progresivamente). Cacheadas.
List<PathMetric> glyphMetrics(GlyphPart part) =>
    _metrics[part] ??= glyphPath(part).computeMetrics().toList();

/// Caja de la forma en la grilla de 24 (para escalar/rotar piezas sobre su centro).
Rect glyphBounds(GlyphPart part) => glyphPath(part).getBounds();

/// Parte de la forma ya "dibujada" hasta [t] (0..1) a lo largo de su trazo.
Path partialGlyphPath(GlyphPart part, double t) {
  if (t >= 1) return glyphPath(part);
  final out = Path();
  if (t <= 0) return out;
  final metrics = glyphMetrics(part);
  final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
  var remaining = total * t;
  for (final m in metrics) {
    if (remaining <= 0) break;
    final len = remaining < m.length ? remaining : m.length;
    out.addPath(m.extractPath(0, len), Offset.zero);
    remaining -= m.length;
  }
  return out;
}

Path _build(List<double> c) {
  final p = Path();
  var i = 0;
  while (i < c.length) {
    switch (c[i].toInt()) {
      case 0:
        p.moveTo(c[i + 1], c[i + 2]);
        i += 3;
      case 1:
        p.lineTo(c[i + 1], c[i + 2]);
        i += 3;
      case 2:
        p.cubicTo(c[i + 1], c[i + 2], c[i + 3], c[i + 4], c[i + 5], c[i + 6]);
        i += 7;
      case 3:
        p.close();
        i += 1;
      default:
        throw StateError('Comando de glifo desconocido: ${c[i]}');
    }
  }
  return p;
}
