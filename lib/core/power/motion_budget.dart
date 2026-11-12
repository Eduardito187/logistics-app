import 'package:flutter/foundation.dart';

/// Presupuesto global de animaciones según la energía del teléfono.
///
/// Es estático a propósito: lo leen widgets de bajo nivel (el ícono animado,
/// el radar del camión) que no son `Consumer` y se instancian por cientos.
/// Lo actualiza `PowerStatusNotifier` cada vez que lee el estado de energía.
///
/// Por qué: una animación visible mantiene la GPU dibujando a 60 cuadros por
/// segundo. Con ahorro de energía o batería baja se cortan las decorativas
/// (respiración del botón central, pulso del radar) y los loops de "cargando"
/// se acortan; el estado se sigue viendo (color/ícono), solo sin movimiento.
abstract final class MotionBudget {
  /// `true` con ahorro de energía del sistema o batería baja.
  static final ValueNotifier<bool> powerSaving = ValueNotifier<bool>(false);

  /// Tope de un loop de "cargando" en condiciones normales. Una carga real
  /// (escaneo, sync, impresión) termina mucho antes; si algo queda colgado en
  /// `loading`, el ícono deja de animar en vez de gastar GPU para siempre.
  static const Duration loadingLoopCap = Duration(seconds: 30);

  /// Tope del loop de "cargando" en ahorro de energía.
  static const Duration loadingLoopCapSaving = Duration(seconds: 5);

  /// Se permiten animaciones puramente decorativas.
  static bool get decorativeAllowed => !powerSaving.value;

  /// Ciclos máximos de un loop de "cargando" de duración [cycle] (mínimo 1).
  static int loadingCyclesFor(Duration cycle) {
    final cap = powerSaving.value ? loadingLoopCapSaving : loadingLoopCap;
    if (cycle <= Duration.zero) return 1;
    final cycles = cap.inMilliseconds ~/ cycle.inMilliseconds;
    return cycles < 1 ? 1 : cycles;
  }

  /// Vuelve al estado por defecto (tests).
  @visibleForTesting
  static void reset() => powerSaving.value = false;
}
