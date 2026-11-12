import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/driver/presentation/controllers/driver_controllers.dart';
import '../../features/driver/presentation/controllers/locally_settled_stops.dart';
import '../../features/picking/presentation/controllers/orders_worklist_controller.dart';
import '../../features/store/presentation/controllers/store_controllers.dart';
import '../../features/supervisor/presentation/controllers/supervisor_controllers.dart';
import '../auth/session.dart';
import 'home_widget_builders.dart';
import 'home_widget_sources.dart';
import 'home_widgets_controller.dart';
import 'home_widgets_prefs.dart';
import 'home_widgets_prefs_notifier.dart';
import 'home_widgets_prefs_store.dart';
import 'home_widgets_service.dart';

/// Reloj de los widgets (día de la ruta y throttling). Seam para tests.
final homeWidgetsClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Controller de los widgets. Seam para tests (`overrideWith` con un servicio
/// falso y un reloj inyectado).
final homeWidgetsControllerProvider = Provider<HomeWidgetsController>(
  (ref) => HomeWidgetsController(
    service: ref.watch(homeWidgetsServiceProvider),
    clock: ref.watch(homeWidgetsClockProvider),
  ),
);

/// ARRANQUE de los widgets de la pantalla de inicio. Se activa UNA vez desde
/// `LogisticsApp.build`:
///
/// ```dart
/// ref.listen(homeWidgetsProvider, (_, _) {});
/// ```
///
/// - Sesión: login confirmado (con las preferencias del usuario leídas) →
///   `signIn`; cierre → `signOut` (solo "clearAll").
/// - Datos: escucha DÉBIL (`weak: true`) de los providers que el inicio ya
///   usa: no los crea, no los mantiene vivos y no dispara pedidos. Si nadie
///   los usa, el widget queda con lo último publicado.
/// - Al pasar a segundo plano publica lo retenido por el throttling.
final homeWidgetsProvider = Provider<void>((ref) {
  final controller = ref.watch(homeWidgetsControllerProvider);
  final clock = ref.watch(homeWidgetsClockProvider);
  var sources = const HomeWidgetSources();

  void publish() {
    final role = controller.role;
    if (role == null) return;
    final hide = ref.read(homeWidgetsPrefsProvider)?.hideCustomer ?? false;
    for (final payload in homeWidgetPayloadsFor(
      role: role,
      sources: sources,
      now: clock(),
      hideCustomer: hide,
    )) {
      controller.onPayload(payload);
    }
  }

  void syncSession() {
    final session = ref.read(sessionProvider);
    if (session == null) {
      sources = const HomeWidgetSources();
      controller.signOut();
      return;
    }
    final userKey = HomeWidgetsPrefsStore.userKeyOf(session.userName);
    final prefs = ref.read(homeWidgetsPrefsProvider);
    // Rol confirmado = sesión + preferencias de ESE usuario ya leídas.
    if (prefs == null || prefs.userKey != userKey) return;
    controller.signIn(
      userKey: userKey,
      role: session.role,
      disabled: prefs.disabledKinds,
    );
    publish();
  }

  ref.listen<Session?>(
    sessionProvider,
    (_, _) => syncSession(),
    fireImmediately: true,
  );
  ref.listen<HomeWidgetsPrefs?>(
    homeWidgetsPrefsProvider,
    (_, _) => syncSession(),
    fireImmediately: true,
  );

  // Fuentes: solo lo que el inicio ya cargó.
  ref.listen(driverRouteProvider, (_, next) {
    final route = next.value;
    if (route == null) return;
    sources = sources.copyWith(driverRoute: route);
    publish();
  }, weak: true);
  ref.listen(locallySettledStopsProvider, (_, next) {
    sources = sources.copyWith(settledStops: next);
    publish();
  }, weak: true);
  ref.listen(ordersToPrepareProvider, (_, next) {
    final orders = next.value;
    if (orders == null) return;
    sources = sources.copyWith(pickingOrders: orders);
    publish();
  }, weak: true);
  ref.listen(storeShipmentsProvider, (_, next) {
    final shipments = next.value;
    if (shipments == null) return;
    sources = sources.copyWith(storeShipments: shipments);
    publish();
  }, weak: true);
  ref.listen(dashboardMetricsProvider, (_, next) {
    final metrics = next.value;
    if (metrics == null) return;
    // El tablero puede estar mirando otro día: el widget es el de HOY.
    if (!isSameRouteDay(ref.read(plansDateProvider), clock())) return;
    sources = sources.copyWith(dashboardMetrics: metrics);
    publish();
  }, weak: true);
  ref.listen(fleetLiveProvider, (_, next) {
    final fleet = next.value;
    if (fleet == null) return;
    sources = sources.copyWith(fleet: fleet);
    publish();
  }, weak: true);

  AppLifecycleListener? listener;
  try {
    listener = AppLifecycleListener(
      onPause: () {
        publish();
        controller.flush();
      },
    );
  } on Object {
    // Sin binding (tests unitarios puros): sin escucha del ciclo de vida.
    listener = null;
  }
  ref.onDispose(() => listener?.dispose());
});
