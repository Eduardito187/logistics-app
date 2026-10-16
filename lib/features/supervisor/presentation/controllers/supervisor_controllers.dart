import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/data7.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/vehicle_live.dart';
import '../../../../core/api/models/vehicle_telemetry_summary.dart';
import '../../domain/dashboard_metrics.dart';
import '../../domain/usecases/get_dashboard_metrics.dart';
import '../../domain/usecases/get_live_fleet.dart';
import '../../domain/usecases/get_plan.dart';
import '../../domain/usecases/get_plan_eta.dart';
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

/// Posiciones en vivo de la flota (telemetría).
final fleetLiveProvider = FutureProvider.autoDispose<List<VehicleLive>>(
  (ref) => ref.watch(getLiveFleetProvider)(),
);

/// Planes del día seleccionado (uno por camión).
final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  final date = ref.watch(plansDateProvider);
  return ref.watch(listPlansProvider)(date);
});

/// Alertas de telemetría, filtradas según el selector de la pantalla.
final alertsProvider = FutureProvider.autoDispose<List<Alert>>((ref) {
  final unacknowledgedOnly = ref.watch(alertsFilterProvider);
  return ref.watch(listAlertsProvider)(unacknowledgedOnly: unacknowledgedOnly);
});

/// Resumen diario de telemetría de un vehículo (al tocar su marcador).
final vehicleSummaryProvider = FutureProvider.autoDispose
    .family<VehicleTelemetrySummary, String>(
      (ref, vehicleId) => ref.watch(getVehicleSummaryProvider)(vehicleId),
    );

/// Tablero resumen del día: agrega envíos, planes y alertas en métricas.
final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>((
  ref,
) {
  final date = ref.watch(plansDateProvider);
  return ref.watch(getDashboardMetricsProvider)(date);
});

/// Detalle de un plan: datos del plan, camión y secuencia de paradas.
/// Family por `planId`; autoDispose para no retener planes al salir del detalle.
final planDetailProvider = FutureProvider.autoDispose.family<Plan, String>(
  (ref, planId) => ref.watch(getPlanProvider)(planId),
);

/// ETA por parada de un plan (secuencia + hora estimada por envío).
final planEtaProvider = FutureProvider.autoDispose.family<Data7, String>(
  (ref, planId) => ref.watch(getPlanEtaProvider)(planId),
);
