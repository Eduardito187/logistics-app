import 'dart:math' as math;

import '../generated/app_icon.g.dart';
import '../icon_glyph.dart';
import '../icon_motion.dart';

/// Animaciones del lote "state_b": estados y feedback (GPS, impresión, cámara,
/// firma, seguridad, acción rápida, avisos silenciados).
final Map<AppIcon, AppIconSpec> kStateBIconSpecs = {
  // El pin cae sobre el suelo y el anillo del suelo aparece al aterrizar.
  AppIcon.place: const AppIconSpec(
    motion: IconMotion.swing,
    loop: IconLoop.locate,
    duration: Duration(milliseconds: 500),
    choreography: _place,
  ),
  // Pin sin señal: la cruz se traza al final.
  AppIcon.gpsOff: const AppIconSpec(
    motion: IconMotion.wiggle,
    loop: IconLoop.blink,
    duration: Duration(milliseconds: 480),
    choreography: _drawAccentLate,
  ),
  // La flecha gira hasta el nuevo rumbo; el anillo pulsa mientras busca.
  AppIcon.navigation: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.locate,
    duration: Duration(milliseconds: 500),
    choreography: _navigation,
  ),
  // La hoja sale de la impresora (y se desliza en loop mientras imprime).
  AppIcon.printing: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.print,
    duration: Duration(milliseconds: 500),
    choreography: _printing,
  ),
  // Flash de obturador: el diafragma se cierra, el flash destella y el marco parpadea.
  AppIcon.capture: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _capture,
  ),
  // Las flechas giran media vuelta (cámara frontal ↔ trasera).
  AppIcon.cameraSwitch: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.spin,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _cameraSwitch,
  ),
  AppIcon.image: const AppIconSpec(
    motion: IconMotion.pop,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 420),
  ),
  // La lapicera recorre la línea mientras la firma se dibuja, y vuelve.
  AppIcon.signature: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    choreography: _signature,
  ),
  // Candado: el gancho baja y cierra al verificar.
  AppIcon.security: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _security,
    successChoreography: _security,
  ),
  AppIcon.badge: const AppIconSpec(
    motion: IconMotion.pop,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 420),
  ),
  // El rayo se "carga" (se traza) y destella una vez con el pulso.
  AppIcon.bolt: const AppIconSpec(
    motion: IconMotion.pulse,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    choreography: _bolt,
  ),
  // El triángulo entra deslizándose hacia la derecha (arrancar).
  AppIcon.play: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 480),
    choreography: _play,
  ),
  // Campana que se sacude; la cruz aparece al silenciar.
  AppIcon.alertsOff: const AppIconSpec(
    motion: IconMotion.wiggle,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    choreography: _drawAccentLate,
  ),
};

PartPose? _place(GlyphPart part, int i, double t) {
  if (part.has('pin')) {
    final land = easeOut(segment(t, 0, .55));
    return PartPose(dy: -3 * (1 - land), opacity: .35 + .65 * land);
  }
  if (part.has('ring')) {
    final s = easeOut(segment(t, .45, .85));
    return PartPose(scale: .6 + .4 * s, opacity: s, draw: 1);
  }
  return null;
}

/// La pieza de acento (la cruz) se traza en la segunda mitad.
PartPose? _drawAccentLate(GlyphPart part, int i, double t) {
  if (part.accent) return PartPose(draw: easeOut(segment(t, .4, .9)));
  return null;
}

PartPose? _navigation(GlyphPart part, int i, double t) {
  if (part.has('arrow')) {
    return PartPose(
      rotation: -.7 * (1 - easeInOut(segment(t, 0, .75))),
      draw: 1,
    );
  }
  return null;
}

PartPose? _printing(GlyphPart part, int i, double t) {
  if (part.has('paper')) {
    final out = easeOut(segment(t, .2, .85));
    return PartPose(dy: -4 * (1 - out), opacity: segment(t, .15, .35), draw: 1);
  }
  return null;
}

PartPose? _capture(GlyphPart part, int i, double t) {
  final shot = hump(segment(t, .1, .5));
  if (part.has('frame')) return PartPose(opacity: 1 - .55 * shot);
  if (part.has('lens')) return PartPose(scale: 1 - .35 * shot);
  if (part.has('flash')) return PartPose(scale: 1 + 1.2 * shot);
  return null;
}

PartPose? _cameraSwitch(GlyphPart part, int i, double t) {
  if (part.has('spin')) return PartPose(rotation: math.pi * easeInOut(t));
  return null;
}

PartPose? _signature(GlyphPart part, int i, double t) {
  final write = easeInOut(segment(t, .15, .8));
  final back = easeInOut(segment(t, .8, 1));
  if (part.has('ink')) return PartPose(draw: easeInOut(segment(t, .1, .8)));
  if (part.has('pen')) {
    // La punta va al inicio de la línea, la recorre y vuelve a su lugar,
    // sin salir del lienzo.
    final reach = easeOut(segment(t, 0, .15)) * (1 - back);
    final dx = (-2.5 + 4.5 * write) * (1 - back) * (t < .15 ? reach : 1);
    return PartPose(dx: dx, dy: 2.4 * reach, draw: 1);
  }
  return null;
}

PartPose? _security(GlyphPart part, int i, double t) {
  if (part.has('shackle')) {
    return PartPose(dy: -2.4 * (1 - easeInOut(segment(t, .1, .7))));
  }
  return null;
}

PartPose? _bolt(GlyphPart part, int i, double t) {
  if (part.has('bolt')) return PartPose(draw: easeOut(segment(t, 0, .6)));
  return null;
}

PartPose? _play(GlyphPart part, int i, double t) {
  if (part.has('tri')) {
    final s = easeOut(segment(t, .1, .7));
    return PartPose(dx: -2.5 * (1 - s), opacity: .3 + .7 * s, draw: 1);
  }
  return null;
}
