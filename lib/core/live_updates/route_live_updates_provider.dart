import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/driver/presentation/controllers/driver_controllers.dart';
import '../../features/driver/presentation/controllers/locally_settled_stops.dart';
import '../../features/driver/presentation/widgets/active_delivery/delivery_map.dart'
    show remainingToStop;
import '../auth/session.dart';
import '../auth/user_role.dart';
import '../location/gps_fix.dart';
import '../location/truck_tracking_service.dart';
import 'live_updates_service.dart';
import 'route_island.dart';
import 'route_live_status.dart';
import 'route_live_status_builder.dart';
import 'route_live_updates_controller.dart';

/// Posición del camión para la ruta en vivo: SOLO la del rastreo que ya corre
/// (no pide lecturas extra al GPS). Seam para tests (`overrideWithValue`).
final routeLiveFixProvider = Provider.autoDispose<GpsFix?>(
  (ref) => ref.watch(truckTrackingProvider.select((s) => s.lastFix)),
);

/// ¿El foreground service del rastreo está arriba? Su notificación comparte el
/// id con la ruta en vivo (una sola notificación). Seam para tests
/// (`overrideWithValue`).
final routeLiveServiceRunningProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(
    truckTrackingProvider.select((s) => s.foregroundServiceRunning),
  ),
);

/// Foto de la ruta del chofer para la notificación en vivo.
///
/// `known == false` mientras todavía no hay ruta (primera carga) o si el
/// chofer está mirando OTRO día en "Mi ruta" (la notificación sigue con la
/// ruta de hoy, no se toca). Con ruta: la foto, o `null` si no hay paradas.
final routeLiveStatusProvider =
    Provider.autoDispose<({bool known, RouteLiveStatus? status})>((ref) {
      final date = ref.watch(selectedDateProvider);
      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      if (!isToday) return (known: false, status: null);

      final route = ref.watch(driverRouteProvider);
      final data = route.value;
      if (data == null) {
        // Error sin ruta previa (sin asignación, 404): no hay nada que
        // mostrar. Cargando: todavía no se sabe.
        return (known: route.hasError && !route.isLoading, status: null);
      }
      final settled = ref.watch(locallySettledStopsProvider);
      final fix = ref.watch(routeLiveFixProvider);
      final stop = currentStopOf(data, settled);
      return (
        known: true,
        status: routeLiveStatusFor(
          route: data,
          settled: settled,
          remaining: stop == null ? null : remainingToStop(data, stop, fix),
        ),
      );
    });

/// Controller de la ruta en vivo, atado al ciclo de vida de la app (Android
/// quita la notificación con la app en pantalla y la vuelve a poner al pasar a
/// segundo plano). Seam para tests: `overrideWithValue` con un controller
/// armado con un servicio falso y un reloj inyectado.
final routeLiveUpdatesControllerProvider =
    Provider<RouteLiveUpdatesController>((ref) {
      final android = defaultTargetPlatform == TargetPlatform.android;
      final controller = RouteLiveUpdatesController(
        service: ref.watch(liveUpdatesServiceProvider),
        hideInForeground: android,
        foreground: _isForegroundNow(),
        onArrived: () => unawaited(_arrivalHaptic()),
      );
      AppLifecycleListener? listener;
      try {
        listener = AppLifecycleListener(
          onStateChange: (state) {
            switch (state) {
              case AppLifecycleState.resumed:
                controller.setForeground(true);
                // Pudo dar el permiso de la isla o activar "Live updates" en
                // los ajustes del sistema: se vuelve a consultar.
                if (android) ref.invalidate(routeIslandAvailabilityProvider);
              case AppLifecycleState.paused:
                controller.setForeground(false);
              // hidden/inactive/detached: transiciones intermedias, nada (no
              // parpadear la notificación al bajar la cortina).
              case AppLifecycleState.inactive:
              case AppLifecycleState.hidden:
              case AppLifecycleState.detached:
                break;
            }
          },
        );
      } on Object {
        // Sin binding (tests unitarios puros): sin escucha del ciclo de vida.
        listener = null;
      }
      ref.onDispose(() {
        listener?.dispose();
        controller.dispose();
      });
      return controller;
    });

/// ARRANQUE de la ruta en vivo (Live Updates de Android 16 / Live Activity +
/// Dynamic Island de iOS). Se activa UNA vez desde `LogisticsApp.build`:
///
/// ```dart
/// ref.listen(routeLiveUpdatesProvider, (_, _) {});
/// ```
///
/// Solo para el rol chofer: con otra sesión (o al cerrar sesión) quita lo que
/// hubiera y no observa la ruta (no dispara pedidos de ruta de otros roles).
final routeLiveUpdatesProvider = Provider<void>((ref) {
  final controller = ref.watch(routeLiveUpdatesControllerProvider);
  final isDriver = ref.watch(
    sessionProvider.select((s) => s?.role == UserRole.driver),
  );
  if (!isDriver) {
    controller.onStatus(null);
    return;
  }
  ref.listen<({bool known, RouteLiveStatus? status})>(routeLiveStatusProvider, (
    _,
    next,
  ) {
    if (!next.known) return;
    controller.onStatus(next.status);
  }, fireImmediately: true);
  // Android: la notificación del foreground service del rastreo ES la de la
  // ruta (mismo id). iOS no tiene ese servicio: no se escucha.
  if (controller.hideInForeground) {
    ref.listen<bool>(
      routeLiveServiceRunningProvider,
      (_, running) => controller.setServiceRunning(running),
      fireImmediately: true,
    );
    // Isla del sistema (Android 16) o isla de DisTrack (pastilla propia).
    ref.listen<RouteIslandMode>(
      routeIslandModeProvider,
      (_, mode) => controller.setIslandMode(mode),
      fireImmediately: true,
    );
  }
});

bool _isForegroundNow() {
  try {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  } on Object {
    return true;
  }
}

/// Vibración larga al llegar a la parada (con guantes y el teléfono en el
/// soporte se siente sin mirar; distinta del "click" corto del escaneo). Sin
/// vibrador: se ignora. Sin timers (no deja nada pendiente en los tests).
Future<void> _arrivalHaptic() async {
  try {
    await HapticFeedback.vibrate();
  } on Object {
    // Sin vibrador o canal: el aviso es un extra.
  }
}
