import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/supervisor/domain/usecases/get_dashboard_metrics.dart';

import '../support/fake_supervisor_repository.dart';
import '../support/supervisor_fixtures.dart';

// GetDashboardMetrics: las tres lecturas del tablero salen en paralelo (antes
// en serie), reusa los planes que se le pasen y relanza el error tal cual.

void main() {
  test('pide envíos, planes y alertas a la vez (en paralelo)', () async {
    final gate = Completer<void>();
    final repo = FakeSupervisorRepository()
      ..dashboardGate = gate.future
      ..shipments = [shipment(ShipmentStatus.delivered)]
      ..plansByDate = [plan(status: PlanStatus.published)]
      ..alerts = [alert()];

    final pending = GetDashboardMetrics(repo)(DateTime(2026, 10, 20));
    await Future<void>.delayed(Duration.zero);

    // Ninguna terminó y las tres ya están en vuelo: no esperan una a la otra.
    expect(repo.shipmentsCalls, 1);
    expect(repo.plansCalls, 1);
    expect(repo.listAlertsCalls, 1);

    gate.complete();
    final metrics = await pending;
    expect(metrics.delivered, 1);
    expect(metrics.activePlans, 1);
    expect(metrics.openAlerts, 1);
  });

  test('las alertas se filtran en el servidor (solo abiertas)', () async {
    final repo = FakeSupervisorRepository();
    await GetDashboardMetrics(repo)(DateTime(2026, 10, 20));
    expect(repo.lastAlertsAcknowledgedArg, isFalse);
  });

  test('con planes ya en caché no los vuelve a pedir', () async {
    final repo = FakeSupervisorRepository();
    final metrics = await GetDashboardMetrics(repo)(
      DateTime(2026, 10, 20),
      plans: Future.value([plan(status: PlanStatus.published)]),
    );
    expect(repo.plansCalls, 0);
    expect(metrics.activePlans, 1);
  });

  test('un fallo se relanza como ApiException (no envuelto)', () async {
    final repo = FakeSupervisorRepository()
      ..plansError = const ApiException(status: 503, title: 'x');
    await expectLater(
      GetDashboardMetrics(repo)(DateTime(2026, 10, 20)),
      throwsA(isA<ApiException>()),
    );
  });
}
