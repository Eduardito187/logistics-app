import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Normaliza una fecha a solo año/mes/día (sin hora) para los filtros del día.
DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Reloj de la fecha del día. Seam para tests (simular el paso de la
/// medianoche); en la app es `DateTime.now`.
final plansClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Fecha seleccionada para los planes del día. Arranca en hoy.
///
/// Mientras el supervisor no elija otro día, la fecha "sigue a hoy": si la app
/// queda abierta pasada la medianoche (sesión persistente, provider sin
/// autoDispose), al volver a primer plano pasa sola al día nuevo en vez de
/// seguir mostrando los planes de ayer. Si eligió un día a mano, se respeta.
class PlansDateNotifier extends Notifier<DateTime> {
  bool _followsToday = true;

  DateTime get _today => _dateOnly(ref.read(plansClockProvider)());

  @override
  DateTime build() {
    _followsToday = true;
    final listener = _lifecycleListener();
    ref.onDispose(() => listener?.dispose());
    return _dateOnly(ref.watch(plansClockProvider)());
  }

  void select(DateTime date) {
    final day = _dateOnly(date);
    _followsToday = day == _today;
    state = day;
  }

  /// Si la fecha sigue a hoy y cambió el día, pasa al día nuevo. Barato e
  /// idempotente: se llama al volver a primer plano y al entrar al inicio.
  void rollOverIfNewDay() {
    if (!_followsToday) return;
    final today = _today;
    if (state != today) state = today;
  }

  /// Escucha el regreso a primer plano. Sin binding de Flutter (tests de
  /// Dart puro) no hay ciclo de vida que escuchar.
  AppLifecycleListener? _lifecycleListener() {
    try {
      return AppLifecycleListener(onResume: rollOverIfNewDay);
    } on FlutterError {
      return null;
    }
  }
}

/// Sin autoDispose a propósito: es un solo `DateTime` compartido por el
/// tablero y la lista de planes (elegir fecha en uno se ve en el otro).
final plansDateProvider = NotifierProvider<PlansDateNotifier, DateTime>(
  PlansDateNotifier.new,
);
