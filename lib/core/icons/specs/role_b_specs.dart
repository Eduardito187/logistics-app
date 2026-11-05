import 'dart:math' as math;

import '../generated/app_icon.g.dart';
import '../icon_glyph.dart';
import '../icon_motion.dart';

/// Animaciones del lote "role_b": acciones de Preparador, Tienda,
/// Transportista y Supervisor. Héroes: scan, receive, pickupScan, dashboard.
final Map<AppIcon, AppIconSpec> kRoleBIconSpecs = {
  // Preparador
  AppIcon.orders: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 440),
    choreography: _orders,
  ),
  AppIcon.scan: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.sweep,
    duration: Duration(milliseconds: 820),
    drawOn: false,
    choreography: _scan,
    successChoreography: _scanSuccess,
  ),
  // Tienda
  AppIcon.receive: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 820),
    choreography: _receive,
    successChoreography: _receiveSuccess,
  ),
  AppIcon.pickupStore: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 460),
    choreography: _pickupStore,
  ),
  // Transportista
  AppIcon.pickupScan: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.sweep,
    duration: Duration(milliseconds: 780),
    choreography: _pickupScan,
    successChoreography: _pickupScanSuccess,
  ),
  AppIcon.deliverScan: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 480),
  ),
  AppIcon.settle: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.print,
    duration: Duration(milliseconds: 460),
    choreography: _settle,
  ),
  // Supervisor
  AppIcon.dashboard: const AppIconSpec(
    motion: IconMotion.stagger,
    duration: Duration(milliseconds: 760),
    drawOn: false,
    choreography: _dashboard,
  ),
  AppIcon.fleet: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 480),
    choreography: _fleet,
  ),
  AppIcon.plans: const AppIconSpec(
    motion: IconMotion.draw,
    duration: Duration(milliseconds: 460),
  ),
  AppIcon.roleAlerts: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 420),
  ),
};

/// Reduce el pop final del acento (pico 1.3 del motor) a [peak], para
/// acentos grandes (marco del escáner) que no deben crecer tanto.
double _tame(double t, {double peak = 1.1}) {
  final s = segment(t, 0.5, 1);
  return popScale(s, peak: peak) / popScale(s, peak: 1.3);
}

// Pedidos: los renglones entran de a uno desde la izquierda.
PartPose? _orders(GlyphPart part, int i, double t) {
  if (!part.has('row')) return null;
  final k = (i - 2).clamp(0, 2);
  final e = easeOut(segment(t, 0.2 + k * 0.15, 0.55 + k * 0.15));
  return PartPose(dx: -2 * (1 - e), opacity: 0.4 + 0.6 * e);
}

// Escanear: el láser recorre el marco (arriba → abajo → centro) y el marco
// "fija" el objetivo con un pop corto.
PartPose? _scan(GlyphPart part, int i, double t) {
  if (part.has('laser')) {
    return PartPose(dy: -4.5 * math.sin(2 * math.pi * easeInOut(t)));
  }
  if (part.has('frame')) return PartPose(scale: _tame(t));
  return null;
}

// Escanear (éxito): las dos mitades del láser giran y forman un check;
// lo sostienen y vuelven a ser láser al final.
PartPose? _scanSuccess(GlyphPart part, int i, double t) {
  final k = easeOut(segment(t, 0, 0.4)) * (1 - easeInOut(segment(t, 0.8, 1)));
  if (part.has('short')) {
    return PartPose(dx: 1.075 * k, dy: 1.575 * k, rotation: math.pi / 4 * k);
  }
  if (part.has('long')) {
    return PartPose(dx: -0.505 * k, dy: 0.305 * k, rotation: -math.pi / 4 * k);
  }
  if (part.has('frame')) return PartPose(scale: _tame(t));
  return null;
}

// Recepción: la tapa (abierta e inclinada) baja y cierra la caja; luego se
// dibuja el tilde de "sellado".
PartPose? _receive(GlyphPart part, int i, double t) {
  if (part.has('lid')) {
    final d = 1 - easeOut(segment(t, 0.1, 0.6));
    return PartPose(dy: -3.5 * d, rotation: -0.22 * d);
  }
  if (part.has('check')) return PartPose(draw: segment(t, 0.6, 0.95));
  return null;
}

// Recepción (éxito): la tapa aprieta el sello y el tilde se redibuja.
PartPose? _receiveSuccess(GlyphPart part, int i, double t) {
  if (part.has('lid')) {
    return PartPose(dy: 0.8 * hump(segment(t, 0, 0.4)));
  }
  if (part.has('check')) return PartPose(draw: segment(t, 0.2, 0.7));
  return null;
}

// Recojo en tienda: el festón del toldo se despliega hacia abajo.
PartPose? _pickupStore(GlyphPart part, int i, double t) {
  if (!part.has('scallop')) return null;
  final e = easeOut(segment(t, 0.15, 0.6));
  return PartPose(dy: -2.5 * (1 - e), opacity: 0.4 + 0.6 * e);
}

// Escanear al recoger: la flecha sube desde el pie del documento (barrido)
// y se asienta en su lugar.
PartPose? _pickupScan(GlyphPart part, int i, double t) {
  if (part.has('arrow')) {
    final d = 1 - easeOut(segment(t, 0.15, 0.7));
    return PartPose(
      dy: 4 * d - 1.2 * hump(segment(t, 0.55, 1)),
      opacity: 0.35 + 0.65 * (1 - d),
    );
  }
  if (part.has('fold')) return PartPose(draw: segment(t, 0, 0.4));
  return null;
}

// Escanear al recoger (éxito): la flecha da un empujón corto hacia arriba.
PartPose? _pickupScanSuccess(GlyphPart part, int i, double t) {
  if (!part.has('arrow')) return null;
  return PartPose(dy: -2 * hump(segment(t, 0, 0.6)));
}

// Liquidaciones: el recibo se desliza hacia abajo, como si se imprimiera.
PartPose? _settle(GlyphPart part, int i, double t) {
  if (!part.has('paper')) return null;
  return PartPose(dy: -2.5 * (1 - easeOut(t)));
}

// Tablero: los mosaicos entran en secuencia (suben y se afirman); siempre
// quedan visibles en tenue para que el tablero se reconozca en cada frame.
// El acento no suma el pop final del motor (ya tiene el pop escalonado).
PartPose? _dashboard(GlyphPart part, int i, double t) {
  if (!part.has('tile')) return null;
  final e = easeOut(segment(t, i * 0.1, i * 0.1 + 0.35));
  final tame = part.accent ? 1 / popScale(segment(t, 0.5, 1), peak: 1.3) : 1.0;
  return PartPose(
    dy: 2.5 * (1 - e),
    opacity: 0.3 + 0.7 * e,
    scale: (0.75 + 0.25 * e) * tame,
  );
}

// Flota en vivo: el pin cae sobre el mapa y su punto late (pop del acento).
PartPose? _fleet(GlyphPart part, int i, double t) {
  if (part.has('pin') || part.has('blip')) {
    return PartPose(dy: -3 * (1 - easeOut(segment(t, 0, 0.55))));
  }
  return null;
}
