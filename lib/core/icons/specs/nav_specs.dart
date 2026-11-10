import 'dart:math' as math;

import '../generated/app_icon.g.dart';
import '../icon_glyph.dart';
import '../icon_motion.dart';

/// Animaciones del lote "nav": las 4 pestañas laterales de la barra flotante
/// (`floating_pill_nav_bar.dart`, 22 dp). El estado `active` rellena las piezas
/// `ds-p-fill` y cada ícono ejecuta su metáfora (brief §4.1). Ninguna pieza
/// arranca invisible: la pestaña se reconoce en cualquier frame.
final Map<AppIcon, AppIconSpec> kNavIconSpecs = {
  // Inicio: el techo se dibuja y las paredes "bajan" a su lugar con el relleno.
  AppIcon.home: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 560),
    choreography: _home,
  ),
  // Tareas: las 4 celdas aparecen en secuencia (pop escalonado 0.1·400 = 40 ms).
  AppIcon.tasks: const AppIconSpec(
    motion: IconMotion.stagger,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 400),
    drawOn: false,
    choreography: _tasks,
  ),
  // Avisos: swing corto de la campana colgando del gancho y se asienta.
  AppIcon.alerts: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 700),
    drawOn: false,
    choreography: _alerts,
  ),
  // Perfil: hombros y cabeza se rellenan de abajo hacia arriba.
  AppIcon.profile: const AppIconSpec(
    motion: IconMotion.fillUp,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 600),
    choreography: _profile,
  ),
};

/// Techo trazado primero; paredes bajan 1.4 a su lugar y la puerta remata.
PartPose? _home(GlyphPart part, int i, double t) {
  if (part.has('roof')) {
    return PartPose(draw: 0.3 + 0.7 * easeOut(segment(t, 0, 0.45)));
  }
  if (part.has('walls')) {
    final k = easeOut(segment(t, 0.2, 0.75));
    return PartPose(dy: -1.4 * (1 - k), draw: 0.4 + 0.6 * k);
  }
  if (part.has('door')) {
    return PartPose(draw: 0.2 + 0.8 * easeOut(segment(t, 0.55, 0.95)));
  }
  return null;
}

/// Cada celda entra desde 0.6 de escala y se afirma en su turno.
PartPose? _tasks(GlyphPart part, int i, double t) {
  if (!part.has('cell')) return null;
  final k = easeOut(segment(t, i * 0.1, i * 0.1 + 0.4));
  return PartPose(scale: 0.6 + 0.4 * k, opacity: 0.3 + 0.7 * k);
}

/// Inclinación de la campana (radianes): oscilación amortiguada corta.
double _bellAngle(double t) => 0.22 * damped(t, cycles: 1.5);

/// La campana gira compensando para pivotar desde el gancho (8 sobre su
/// centro); el badajo la sigue con un leve retraso, como un péndulo.
PartPose? _alerts(GlyphPart part, int i, double t) {
  if (part.has('bell')) {
    final a = _bellAngle(t);
    return PartPose(rotation: a, dx: -8 * math.sin(a));
  }
  if (part.has('clapper')) {
    final a = _bellAngle(segment(t, 0.08, 1));
    return PartPose(rotation: a * 0.5, dx: -17 * math.sin(a));
  }
  return null;
}

/// Hombros primero; la cabeza se dibuja después subiendo 1.2 a su lugar.
PartPose? _profile(GlyphPart part, int i, double t) {
  if (part.has('body')) {
    return PartPose(draw: 0.3 + 0.7 * easeOut(segment(t, 0, 0.55)));
  }
  if (part.has('head')) {
    final k = easeOut(segment(t, 0.3, 0.85));
    return PartPose(dy: 1.2 * (1 - k), draw: 0.25 + 0.75 * k);
  }
  return null;
}
