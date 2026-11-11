import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'icon_glyph.dart';

/// Movimiento del ícono COMPLETO al activarse / tocarse (una sola vez).
enum IconMotion {
  /// Gira una vuelta (recargar, sincronizar, ajustes).
  spin,

  /// Late: crece y vuelve (en vivo, acción rápida, IA).
  pulse,

  /// Rebota hacia arriba (alertas, avisos).
  bounce,

  /// "Pop" de escala con rebote (check, agregar, éxito).
  pop,

  /// Se sacude girando (papelera, llave, candado, teléfono).
  wiggle,

  /// Empuja hacia la derecha (avanzar, enviar, camión).
  nudgeRight,

  /// Empuja hacia la izquierda (volver, deshacer).
  nudgeLeft,

  /// Empuja hacia arriba (subir, cargar).
  nudgeUp,

  /// Empuja hacia abajo (bajar, recibir, desplegar).
  nudgeDown,

  /// Se balancea colgando de abajo (pin, bandera, etiqueta).
  swing,

  /// Parpadea (ojo, visibilidad).
  blink,

  /// Solo se redibuja (documentos, listas, firma): sin mover el conjunto.
  draw,

  /// Las piezas aparecen en secuencia con pop escalonado (grillas, tableros).
  stagger,

  /// El relleno sube de abajo hacia arriba (casa, persona).
  fillUp,
}

/// Loop mientras el ícono está en [AppIconState.loading] (o `ambient`).
enum IconLoop {
  /// Gira el ícono (o las piezas `ds-p-spin`).
  spin,

  /// Late suave.
  pulse,

  /// Láser que barre el ícono de arriba abajo (escaneo).
  sweep,

  /// Anillo que se expande y se desvanece (buscando GPS); usa piezas `ds-p-ring`.
  locate,

  /// La hoja (`ds-p-paper`) sale de la impresora.
  print,

  /// Respiración muy sutil 1.0↔1.02 (botón central en reposo).
  breathe,

  /// Parpadeo de opacidad.
  blink,
}

/// Pose de una pieza en un instante de la coreografía (unidades de la grilla 24).
@immutable
class PartPose {
  const PartPose({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotation = 0,
    this.opacity = 1,
    this.draw,
  });

  final double dx;
  final double dy;
  final double scale;

  /// Radianes, sobre el centro de la pieza.
  final double rotation;
  final double opacity;

  /// Fracción del trazo dibujada (0..1). `null` = la del dibujo progresivo general.
  final double? draw;

  static const identity = PartPose();
}

/// Coreografía por pieza (íconos "héroe"): dado el progreso [t] (0..1, ya con
/// curva) devuelve la pose de cada pieza, o `null` para dejarla como está.
typedef PartPoser = PartPose? Function(GlyphPart part, int index, double t);

/// Cómo se anima cada [AppIcon]. Lo definen los lotes en `specs/*.dart`.
@immutable
class AppIconSpec {
  const AppIconSpec({
    this.motion = IconMotion.pop,
    this.loop = IconLoop.pulse,
    this.duration = const Duration(milliseconds: 480),
    this.drawOn = true,
    this.choreography,
    this.successChoreography,
  });

  /// Movimiento del conjunto al activarse o al tocarlo.
  final IconMotion motion;

  /// Loop en estado `loading`.
  final IconLoop loop;

  /// Duración de la animación de activación (200–500 ms; héroes hasta 900 ms).
  final Duration duration;

  /// Si al activarse el trazo se redibuja en cascada.
  final bool drawOn;

  /// Coreografía por pieza al activarse (íconos héroe: la metáfora "ejecuta").
  final PartPoser? choreography;

  /// Coreografía por pieza para `success` (si difiere de la de activación).
  final PartPoser? successChoreography;

  static const fallback = AppIconSpec();
}

// ---------------------------------------------------------------------------
// Curvas y helpers para escribir coreografías y movimientos.
// ---------------------------------------------------------------------------

/// Sube y vuelve: 0→1→0 a lo largo de t (seno).
double hump(double t) => math.sin(math.pi * t.clamp(0.0, 1.0));

/// Progreso local de un tramo [start, end] dentro de t (0..1, recortado).
double segment(double t, double start, double end) =>
    ((t - start) / (end - start)).clamp(0.0, 1.0);

/// easeOutCubic.
double easeOut(double t) => 1 - math.pow(1 - t.clamp(0.0, 1.0), 3).toDouble();

/// easeInOut (cúbica).
double easeInOut(double t) {
  final x = t.clamp(0.0, 1.0);
  return x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
}

/// Rebote de escala 1→peak→undershoot→1 (pop).
double popScale(double t, {double peak = 1.25}) {
  if (t < 0.45) return 1 + (peak - 1) * easeOut(t / 0.45);
  if (t < 0.75) return peak - (peak - 0.95) * easeInOut((t - 0.45) / 0.3);
  return 0.95 + 0.05 * easeOut((t - 0.75) / 0.25);
}

/// Oscilación amortiguada (sacudidas): amplitud que se apaga hacia t=1.
double damped(double t, {double cycles = 2}) =>
    math.sin(t * cycles * 2 * math.pi) * (1 - t.clamp(0.0, 1.0));
