import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supervisor_repository_impl.dart';
import '../dashboard_metrics.dart';
import '../repositories/supervisor_repository.dart';

/// Query: tablero resumen del día. Agrega envíos, planes y alertas del día en
/// las métricas puras [DashboardMetrics].
class GetDashboardMetrics {
  const GetDashboardMetrics(this._repo);

  final SupervisorRepository _repo;

  Future<DashboardMetrics> call(DateTime date) async {
    final shipments = await _repo.listShipments();
    final plans = await _repo.listPlansByDate(date);
    final alerts = await _repo.listTelemetryAlerts();
    return DashboardMetrics.from(
      shipments: shipments,
      plans: plans,
      alerts: alerts,
    );
  }
}

final getDashboardMetricsProvider = Provider<GetDashboardMetrics>(
  (ref) => GetDashboardMetrics(ref.watch(supervisorRepositoryProvider)),
);
