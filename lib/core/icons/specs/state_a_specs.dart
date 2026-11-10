import 'dart:math' as math;

import '../generated/app_icon.g.dart';
import '../icon_glyph.dart';
import '../icon_motion.dart';

/// Animaciones del lote "state_a" (estados y feedback, Flutter puro).
/// Priorizan legibilidad: movimientos cortos, sin rebotes exagerados.
final Map<AppIcon, AppIconSpec> kStateAIconSpecs = {
  // Éxito: el círculo se cierra y después el tilde se dibuja (+ pop del motor).
  AppIcon.success: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 480),
    choreography: _accentLast,
  ),
  AppIcon.check: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 420),
    choreography: _accentLast,
  ),
  AppIcon.verified: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 480),
    choreography: _accentLast,
  ),
  // Error: el motor ya sacude + pulso ámbar; al tocar, un salto corto.
  AppIcon.error: const AppIconSpec(
    motion: IconMotion.bounce,
    duration: Duration(milliseconds: 400),
    choreography: _accentLast,
  ),
  AppIcon.cancel: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 420),
    choreography: _accentLast,
  ),
  // Pendiente: la manecilla da una vuelta suave alrededor del centro (500 ms, §5).
  AppIcon.pending: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _pendingHand,
  ),
  // Sincronizando: las flechas (ds-p-spin) giran sutil mientras sincroniza.
  AppIcon.syncing: const AppIconSpec(
    motion: IconMotion.spin,
    loop: IconLoop.spin,
    duration: Duration(milliseconds: 500),
    drawOn: false,
  ),
  AppIcon.refresh: const AppIconSpec(
    motion: IconMotion.spin,
    loop: IconLoop.spin,
    duration: Duration(milliseconds: 500),
    drawOn: false,
  ),
  AppIcon.cloudDone: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 480),
    choreography: _accentLast,
  ),
  AppIcon.cloudOff: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 420),
    choreography: _accentLast,
  ),
  // Wi-Fi: la señal se propaga del punto hacia afuera.
  AppIcon.wifi: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.blink,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _wifiWaves,
  ),
  AppIcon.wifiOff: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 420),
    choreography: _accentLast,
  ),
  AppIcon.qrCode: const AppIconSpec(
    motion: IconMotion.stagger,
    duration: Duration(milliseconds: 480),
    drawOn: false,
  ),
  // Velocidad: la aguja sube desde abajo a la izquierda hasta su posición.
  AppIcon.speed: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 500),
    choreography: _speedNeedle,
  ),
};

/// La estructura se dibuja primero y la pieza clave (acento) se traza al final.
PartPose? _accentLast(GlyphPart part, int i, double t) {
  if (part.accent) return PartPose(draw: easeOut(segment(t, .35, .85)));
  if (part.fill) return null;
  return PartPose(draw: easeOut(segment(t, 0, .45)));
}

/// Pose que gira la pieza [angle] radianes alrededor del pivote ([px], [py]),
/// compensando que el motor rota sobre el centro de la pieza.
PartPose _rotateAround(GlyphPart part, double angle, double px, double py) {
  final c = glyphBounds(part).center;
  final vx = c.dx - px;
  final vy = c.dy - py;
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  return PartPose(
    rotation: angle,
    dx: vx * cos - vy * sin + px - c.dx,
    dy: vx * sin + vy * cos + py - c.dy,
  );
}

/// Manecilla del reloj: una vuelta completa sobre el centro (12, 12).
PartPose? _pendingHand(GlyphPart part, int i, double t) {
  if (!part.has('spin')) return null;
  return _rotateAround(part, easeInOut(t) * 2 * math.pi, 12, 12);
}

/// Aguja del velocímetro: arranca baja (izquierda) y sube a su lugar.
PartPose? _speedNeedle(GlyphPart part, int i, double t) {
  if (!part.accent) return null;
  final angle = -1.9 * (1 - easeOut(segment(t, .15, 1)));
  return _rotateAround(part, angle, 12, 13.5);
}

/// Ondas del Wi-Fi: el punto aparece y cada arco se enciende en secuencia.
PartPose? _wifiWaves(GlyphPart part, int i, double t) {
  final p = easeOut(segment(t, i * .2, i * .2 + .4));
  return PartPose(opacity: p, scale: .85 + .15 * p);
}
