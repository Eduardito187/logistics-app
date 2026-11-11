import '../generated/app_icon.g.dart';
import '../icon_glyph.dart';
import '../icon_motion.dart';

/// Animaciones del lote "role_a": acciones del CHOFER.
///
/// `deliver` es la acción estrella (botón central): el camión avanza un tramo
/// y deja el paquete (`ds-p-box`) detrás. El resto son micro-coreografías
/// cortas que materializan la metáfora de cada tarea (brief §4.2).
final Map<AppIcon, AppIconSpec> kRoleAIconSpecs = {
  // HERO: el camión entra avanzando y suelta la caja por atrás.
  AppIcon.deliver: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 860),
    drawOn: false,
    choreography: _deliver,
    successChoreography: _deliverSuccess,
  ),
  // El pin cae sobre el punto y la línea de ruta se traza.
  AppIcon.route: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _route,
  ),
  // Mapa plegado: se redibuja en cascada.
  AppIcon.map: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 480),
  ),
  // Hoja de calendario y la tilde que se dibuja al final.
  AppIcon.myDay: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 480),
    choreography: _myDay,
  ),
  // Los ítems se tildan uno tras otro.
  AppIcon.checklist: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _checklist,
  ),
  // La caja sube y la flecha la empuja hacia el camión.
  AppIcon.load: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 480),
    drawOn: false,
    choreography: _load,
  ),
  // Anillo que se cierra sobre el punto y el punto se fija.
  AppIcon.gps: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.locate,
    duration: Duration(milliseconds: 500),
    drawOn: false,
    choreography: _gps,
  ),
  // Triángulo con "!" que parpadea una vez.
  AppIcon.incident: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.blink,
    duration: Duration(milliseconds: 480),
    choreography: _incident,
  ),
  // Las barras crecen desde la base, en secuencia.
  AppIcon.vehicleSummary: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    choreography: _vehicleSummary,
  ),
  // Surtidor: la gota cae dentro del visor.
  AppIcon.fuel: const AppIconSpec(
    motion: IconMotion.draw,
    loop: IconLoop.pulse,
    duration: Duration(milliseconds: 500),
    choreography: _fuel,
  ),
};

// ---------------------------------------------------------------------------
// Coreografías por pieza (t ya en 0..1).
// ---------------------------------------------------------------------------

/// Camión: arranca 4.5 atrás y avanza; la caja viaja en la caja de carga,
/// sale por la puerta trasera y baja al piso (sin rebote).
PartPose? _deliver(GlyphPart part, int i, double t) {
  const back = 4.5;
  if (part.has('truck')) {
    return PartPose(dx: -back * (1 - easeOut(segment(t, 0, .75))));
  }
  if (part.has('box')) {
    // Al inicio la caja está dentro de la carga (3.6 a la derecha, 4.5 arriba).
    final slide = easeInOut(segment(t, .1, .5));
    final drop = easeInOut(segment(t, .45, .8));
    return PartPose(
      dx: 3.6 * (1 - slide),
      dy: -4.5 * (1 - drop),
      scale: .85 + .15 * slide,
    );
  }
  return null;
}

/// Éxito de la entrega: el camión se aparta un poco y la caja se "sella"
/// (se redibuja su contorno y sube apenas).
PartPose? _deliverSuccess(GlyphPart part, int i, double t) {
  if (part.has('truck')) {
    return PartPose(dx: 1.5 * hump(t), opacity: 1 - .5 * hump(t));
  }
  if (part.has('box')) {
    return PartPose(dy: -1.5 * hump(t), draw: easeOut(segment(t, 0, .6)));
  }
  return null;
}

/// Ruta: la línea se traza y el pin cae desde arriba sobre su destino.
PartPose? _route(GlyphPart part, int i, double t) {
  if (part.has('route')) return PartPose(draw: easeInOut(segment(t, 0, .6)));
  if (part.has('pin')) {
    final k = segment(t, .35, .85);
    return PartPose(dy: -6 * (1 - easeOut(k)), opacity: segment(t, .35, .5));
  }
  return null;
}

/// Mi día: la tilde se dibuja después de la hoja.
PartPose? _myDay(GlyphPart part, int i, double t) {
  if (part.has('tick')) return PartPose(draw: easeOut(segment(t, .45, 1)));
  return null;
}

/// Checklist: las tres tildes se dibujan en secuencia (los renglones quedan).
PartPose? _checklist(GlyphPart part, int i, double t) {
  for (var k = 0; k < 3; k++) {
    if (part.has('c${k + 1}')) {
      final start = .05 + k * .25;
      return PartPose(draw: easeOut(segment(t, start, start + .35)));
    }
  }
  return null;
}

/// Carga: la caja sube desde abajo y la flecha la sigue hacia arriba.
PartPose? _load(GlyphPart part, int i, double t) {
  if (part.has('box')) {
    return PartPose(dy: 3 * (1 - easeOut(segment(t, 0, .6))));
  }
  if (part.has('arrow')) {
    return PartPose(
      dy: 4 * (1 - easeOut(segment(t, .25, .85))),
      opacity: segment(t, .25, .45),
    );
  }
  return null;
}

/// GPS: el anillo entra grande y se cierra; al final el punto se fija.
PartPose? _gps(GlyphPart part, int i, double t) {
  if (part.has('ring')) {
    final k = easeOut(segment(t, 0, .6));
    return PartPose(scale: 1.35 - .35 * k, opacity: .35 + .65 * k);
  }
  if (part.has('dot')) return PartPose(scale: easeOut(segment(t, .5, .85)));
  return null;
}

/// Incidente: el "!" se apaga y vuelve una sola vez.
PartPose? _incident(GlyphPart part, int i, double t) {
  if (part.has('bang')) {
    return PartPose(opacity: 1 - .85 * hump(segment(t, .3, .85)));
  }
  return null;
}

/// Resumen: cada barra crece desde la base (el trazo va de abajo hacia arriba).
PartPose? _vehicleSummary(GlyphPart part, int i, double t) {
  if (part.has('bar')) {
    final start = (i - 1) * .15;
    return PartPose(draw: easeOut(segment(t, start, start + .55)));
  }
  return null;
}

/// Combustible: la gota cae dentro del visor del surtidor.
PartPose? _fuel(GlyphPart part, int i, double t) {
  if (part.has('drop')) {
    return PartPose(
      dy: -3.5 * (1 - easeOut(segment(t, .3, .8))),
      opacity: segment(t, .3, .45),
    );
  }
  return null;
}
