import '../generated/app_icon.g.dart';
import '../icon_motion.dart';

/// Animaciones del lote "util_a": utilitarios nítidos con una micro-reacción
/// al tocar (el motor ya aprieta 0.9). Sin coreografías por pieza ni redibujo
/// del trazo: el ícono se mueve entero y el acento remata con su pop.
final Map<AppIcon, AppIconSpec> kUtilAIconSpecs = {
  // Navegación interna: empujan en la dirección a la que llevan.
  AppIcon.chevronRight: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 260),
    drawOn: false,
  ),
  AppIcon.arrowForward: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 280),
    drawOn: false,
  ),
  AppIcon.expandMore: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 260),
    drawOn: false,
  ),
  // Cerrar: sacudida corta.
  AppIcon.close: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  // Agregar / quitar: pop corto.
  AppIcon.add: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 280),
    drawOn: false,
  ),
  AppIcon.remove: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 260),
    drawOn: false,
  ),
  // Buscar: la lupa se balancea como quien revisa.
  AppIcon.search: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  // Ajustes: el engranaje (ds-p-spin) gira una vuelta.
  AppIcon.settings: const AppIconSpec(
    motion: IconMotion.spin,
    loop: IconLoop.spin,
    duration: Duration(milliseconds: 480),
    drawOn: false,
  ),
  // Cerrar sesión: la flecha sale de la puerta.
  AppIcon.logout: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  // Teléfonos: vibran.
  AppIcon.call: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 340),
    drawOn: false,
  ),
  AppIcon.phone: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  // Correo / enviar: avanzan hacia el destinatario.
  AppIcon.mail: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  AppIcon.send: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  // Soporte / acuerdo: latido amable.
  AppIcon.support: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  AppIcon.handshake: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  // Herramientas: la llave gira un poco (sacudida).
  AppIcon.build: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 360),
    drawOn: false,
  ),
  // Ahorro / pagos: pop (la moneda / el billete rematan con el pop del acento).
  AppIcon.savings: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 320),
    drawOn: false,
  ),
  AppIcon.payments: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  // Personas.
  AppIcon.supervisor: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  AppIcon.personOff: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  // Equipos y red: latido corto.
  AppIcon.devices: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  AppIcon.lan: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
};
