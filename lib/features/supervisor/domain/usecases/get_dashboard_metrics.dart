import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/alert.dart';
import '../../../../core/api/models/plan.dart';
import '../../../../core/api/models/shipment.dart';
import '../../data/repositories/supervisor_repository_impl.dart';
import '../dashboard_metrics.dart';
import '../repositories/supervisor_repository.dart';

/// Query: tablero resumen del día. Agrega envíos, planes y alertas del día en
/// las métricas puras [DashboardMetrics].
class GetDashboardMetrics {
  const GetDashboardMetrics(this._repo);

  final SupervisorRepository _repo;

  /// Las tres lecturas salen **en paralelo** (antes iban en serie: 3 RTT por
  /// apertura del tablero; ahora 1).
  ///
  /// [plans]: planes del día ya en vuelo o en caché (los de la lista "Rutas en
  /// curso"), para no pedir dos veces el mismo `listPlansByDate`. Si no se
  /// pasa, se piden al repositorio.
  ///
  /// Las alertas se piden ya filtradas en el servidor (`acknowledged=false`):
  /// el tablero solo cuenta las abiertas y así la respuesta es más chica.
  Future<DashboardMetrics> call(
    DateTime date, {
    Future<List<Plan>>? plans,
  }) async {
    // `Future.wait` (y no el `.wait` de records) para que el primer fallo se
    // relance tal cual (ApiException con su mensaje en español) en vez de
    // envuelto en un ParallelWaitError.
    final results = await Future.wait<Object>([
      _repo.listShipments(),
      plans ?? _repo.listPlansByDate(date),
      _repo.listTelemetryAlerts(acknowledged: false),
    ], eagerError: true);
    final shipments = results[0] as List<Shipment>;
    final dayPlans = results[1] as List<Plan>;
    final alerts = results[2] as List<Alert>;
    return DashboardMetrics.from(
      shipments: shipments,
      plans: dayPlans,
      alerts: alerts,
    );
  }
}

final getDashboardMetricsProvider = Provider<GetDashboardMetrics>(
  (ref) => GetDashboardMetrics(ref.watch(supervisorRepositoryProvider)),
);
