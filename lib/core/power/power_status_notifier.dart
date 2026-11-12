import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion_budget.dart';
import 'power_channel.dart';
import 'power_status.dart';

/// Estado de energía vigente del teléfono.
///
/// Sin timers propios (un timer periódico despierta la CPU aunque no haga
/// nada): se lee al crear el provider, al volver la app a primer plano (el
/// usuario suele activar el ahorro desde la bandeja, lo que pasa por
/// `inactive → resumed`) y a pedido con [refreshIfStale] — el rastreo del
/// camión lo llama en cada envío por lote (cada 1–2 min) para seguir la
/// batería durante la ruta aunque la app quede en segundo plano.
///
/// Además publica el resultado en [MotionBudget] para que los widgets de bajo
/// nivel recorten animaciones decorativas.
class PowerStatusNotifier extends Notifier<PowerStatus> {
  /// Antigüedad máxima de la lectura para [refreshIfStale].
  static const Duration maxAge = Duration(minutes: 3);

  AppLifecycleListener? _lifecycle;
  DateTime? _readAt;
  Future<void>? _inFlight;

  @override
  PowerStatus build() {
    try {
      _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    } on Object {
      // Sin WidgetsBinding (tests unitarios puros): solo lecturas a pedido.
      _lifecycle = null;
    }
    ref.onDispose(() => _lifecycle?.dispose());
    // Primera lectura sin bloquear el build (el estado arranca "desconocido",
    // que equivale a comportamiento normal).
    scheduleMicrotask(() => unawaited(refresh()));
    return PowerStatus.unknown;
  }

  /// Relee el estado del sistema. Nunca lanza; lecturas simultáneas se suman.
  Future<void> refresh() {
    final pending = _inFlight;
    if (pending != null) return pending;
    final run = () async {
      if (!ref.mounted) return;
      final status = await ref.read(powerChannelProvider).read();
      if (!ref.mounted) return;
      _readAt = DateTime.now();
      MotionBudget.powerSaving.value = status.shouldSaveEnergy;
      if (status != state) state = status;
    }().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  /// Relee solo si la última lectura tiene más de [maxAge] (barato de llamar
  /// seguido: no toca el canal nativo si el dato es reciente).
  Future<void> refreshIfStale({DateTime? now}) {
    final at = _readAt;
    final current = now ?? DateTime.now();
    if (at != null && current.difference(at) < maxAge) return Future.value();
    return refresh();
  }
}

final powerStatusProvider = NotifierProvider<PowerStatusNotifier, PowerStatus>(
  PowerStatusNotifier.new,
);
