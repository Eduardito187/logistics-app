import '../generated/app_icon.g.dart';
import '../icon_motion.dart';

/// Animaciones del lote "util_b": utilitarios nítidos con micro-reacción al
/// tocar (el motor ya aprieta 0.9). Sin coreografías.
final Map<AppIcon, AppIconSpec> kUtilBIconSpecs = {
  // Conectividad: enchufar (sube) y señal que late.
  AppIcon.usb: const AppIconSpec(
    motion: IconMotion.nudgeUp,
    duration: Duration(milliseconds: 320),
  ),
  AppIcon.bluetooth: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 360),
  ),

  // Bajar / guardar: empujan hacia abajo.
  AppIcon.systemUpdate: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 360),
  ),
  AppIcon.download: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 360),
  ),
  AppIcon.save: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 300),
  ),
  AppIcon.copy: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 320),
  ),

  // Papelera que se sacude.
  AppIcon.delete: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 400),
  ),

  // Ojo que parpadea al togglear la contraseña.
  AppIcon.visibility: const AppIconSpec(
    motion: IconMotion.blink,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),
  AppIcon.visibilityOff: const AppIconSpec(
    motion: IconMotion.blink,
    duration: Duration(milliseconds: 300),
    drawOn: false,
  ),

  // PIN: los puntos aparecen uno tras otro, como dígitos tecleados.
  AppIcon.pin: const AppIconSpec(
    motion: IconMotion.stagger,
    duration: Duration(milliseconds: 420),
  ),
  AppIcon.keyboard: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 260),
  ),

  // Etiquetas y bandera: cuelgan y se balancean.
  AppIcon.newLabel: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 320),
  ),
  AppIcon.labelOff: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 360),
  ),
  AppIcon.flag: const AppIconSpec(
    motion: IconMotion.swing,
    duration: Duration(milliseconds: 480),
  ),

  AppIcon.swap: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 320),
  ),
  AppIcon.zoomOut: const AppIconSpec(
    motion: IconMotion.pulse,
    duration: Duration(milliseconds: 340),
  ),

  // Sol: una vuelta lenta de los rayos (el dibujo es simétrico).
  AppIcon.sun: const AppIconSpec(
    motion: IconMotion.spin,
    duration: Duration(milliseconds: 500),
  ),
  AppIcon.vibration: const AppIconSpec(
    motion: IconMotion.wiggle,
    duration: Duration(milliseconds: 320),
  ),
  AppIcon.outbound: const AppIconSpec(
    motion: IconMotion.nudgeRight,
    duration: Duration(milliseconds: 320),
  ),
  AppIcon.radioUnchecked: const AppIconSpec(
    motion: IconMotion.pop,
    duration: Duration(milliseconds: 260),
    drawOn: false,
  ),
  AppIcon.inbox: const AppIconSpec(
    motion: IconMotion.nudgeDown,
    duration: Duration(milliseconds: 340),
  ),
};
