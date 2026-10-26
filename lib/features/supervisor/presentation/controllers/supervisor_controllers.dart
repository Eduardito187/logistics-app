import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/data7.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/dashboard_metrics.dart';
import '../../domain/usecases/get_dashboard_metrics.dart';
import '../../domain/usecases/get_live_fleet.dart';
import '../../domain/usecases/get_plan.dart';
import '../../domain/usecases/get_plan_eta.dart';
import '../../domain/usecases/get_vehicle_plates.dart';
import '../../domain/usecases/get_vehicle_summary.dart';
import '../../domain/usecases/list_alerts.dart';
import '../../domain/usecases/list_plans.dart';
import 'alerts_filter_notifier.dart';
import 'plans_date_notifier.dart';

// Los notifiers de estado de pantalla (fecha de planes y filtro de alertas)
// viven en su propio archivo; se reexportan para no cambiar los imports de las
// pantallas ni de los tests.
export 'alerts_filter_notifier.dart';
export 'plans_date_notifier.dart';

/// Lecturas (Riverpod) del supervisor. Solo dependen de casos de uso; nunca del
/// cliente API.

/// Caché corta atada a la sesión: cerrar y entrar con otro usuario dentro del
/// plazo no muestra datos del anterior.
void _cachePerSession(Ref ref) {
  ref.cacheFor(CacheTtl.short);
  ref.watch(sessionProvider.select((s) => (s?.token, s?.userName)));
}

/// Posiciones en vivo de la flota (telemetría).
final fleetLiveProvider = FutureProvider.autoDispose<List<VehicleLive>>(
  (ref) => ref.watch(getLiveFleetProvider)(),
);

/// Planes del día seleccionado (uno por camión).
///
/// Caché corta: volver a "Rutas en curso" (o del detalle a la lista) no repite
/// el request ni muestra spinner; el tablero lee este mismo provider.
final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  _cachePerSession(ref);
  final date = ref.watch(plansDateProvider);
  return ref.watch(listPlansProvider)(date);
});

/// Alertas de telemetría, filtradas según el selector de la pantalla.
final alertsProvider = FutureProvider.autoDispose<List<Alert>>((ref) {
  _cachePerSession(ref);
  final unacknowledgedOnly = ref.watch(alertsFilterProvider);
  return ref.watch(listAlertsProvider)(unacknowledgedOnly: unacknowledgedOnly);
});

/// Placas de la flota por id de vehículo. Se lee una vez por sesión (las
/// placas casi no cambian) y no se descarta al salir de una pantalla.
final vehiclePlatesProvider = FutureProvider<Map<String, String>>(
  (ref) => ref.watch(getVehiclePlatesProvider)(),
);

/// Resumen diario de telemetría de un vehículo (al tocar su marcador).
final vehicleSummaryProvider = FutureProvider.autoDispose
    .family<VehicleTelemetrySummary, String>(
      (ref, vehicleId) => ref.watch(getVehicleSummaryProvider)(vehicleId),
    );

/// Tablero resumen del día: agrega envíos, planes y alertas en métricas.
///
/// Los planes salen de [plansProvider] (mismo request que "Rutas en curso",
/// compartido y cacheado) y las tres lecturas van en paralelo. Caché corta:
/// entrar y salir del tablero no repite los 3 requests.
final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>((
  ref,
) {
  _cachePerSession(ref);
  final date = ref.watch(plansDateProvider);
  return ref.watch(getDashboardMetricsProvider)(
    date,
    plans: ref.watch(plansProvider.future),
  );
});

/// Detalle de un plan: datos del plan, camión y secuencia de paradas.
/// Family por `planId`; caché corta (ir y volver del detalle no lo repide) y
/// después se libera para no retener planes.
final planDetailProvider = FutureProvider.autoDispose.family<Plan, String>((
  ref,
  planId,
) {
  ref.cacheFor(CacheTtl.short);
  return ref.watch(getPlanProvider)(planId);
});

/// ETA por parada de un plan (secuencia + hora estimada por envío).
final planEtaProvider = FutureProvider.autoDispose.family<Data7, String>((
  ref,
  planId,
) {
  ref.cacheFor(CacheTtl.short);
  return ref.watch(getPlanEtaProvider)(planId);
});
