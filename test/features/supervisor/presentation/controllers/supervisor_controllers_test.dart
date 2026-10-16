import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';

import '../../support/fake_supervisor_repository.dart';
import '../../support/supervisor_fixtures.dart';

// Providers de lectura del supervisor: delegan en los casos de uso y reaccionan
// al estado de pantalla (fecha de planes, filtro de alertas).

ProviderContainer _container(FakeSupervisorRepository repo) {
  final container = ProviderContainer(
    overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('fleetLiveProvider devuelve las posiciones de la flota', () async {
    final repo = FakeSupervisorRepository()..fleet = [vehicleLive()];
    final container = _container(repo);
    container.listen(fleetLiveProvider, (_, _) {});

    final value = await container.read(fleetLiveProvider.future);
    expect(value, hasLength(1));
  });

  test(
    'plansProvider usa la fecha seleccionada y reacciona al cambiarla',
    () async {
      final repo = FakeSupervisorRepository()..plansByDate = const [];
      final container = _container(repo);
      container.listen(plansProvider, (_, _) {});

      await container.read(plansProvider.future);
      final firstDate = repo.lastPlansDate;
      expect(firstDate, isNotNull);

      container.read(plansDateProvider.notifier).select(DateTime(2026, 5, 20));
      await container.read(plansProvider.future);

      expect(repo.lastPlansDate, DateTime(2026, 5, 20));
    },
  );

  test(
    'alertsProvider pide acknowledged=false por defecto y null al ver todas',
    () async {
      final repo = FakeSupervisorRepository()..alerts = const [];
      final container = _container(repo);
      container.listen(alertsProvider, (_, _) {});

      await container.read(alertsProvider.future);
      expect(repo.lastAlertsAcknowledgedArg, isFalse);

      container
          .read(alertsFilterProvider.notifier)
          .setUnacknowledgedOnly(value: false);
      await container.read(alertsProvider.future);
      expect(repo.lastAlertsAcknowledgedArg, isNull);
    },
  );

  test('dashboardMetricsProvider agrega envíos, planes y alertas', () async {
    final repo = FakeSupervisorRepository()
      ..shipments = [
        shipment(ShipmentStatus.delivered),
        shipment(ShipmentStatus.delivered, id: 's2'),
        shipment(ShipmentStatus.failed),
      ]
      ..plansByDate = [plan(status: PlanStatus.published)]
      ..alerts = [alert()];
    final container = _container(repo);
    container.listen(dashboardMetricsProvider, (_, _) {});

    final metrics = await container.read(dashboardMetricsProvider.future);

    expect(metrics.delivered, 2);
    expect(metrics.failed, 1);
    expect(metrics.activePlans, 1);
    expect(metrics.openAlerts, 1);
    expect(metrics.fulfillmentRate, closeTo(2 / 3, 1e-9));
  });

  test('planDetailProvider devuelve el plan por id', () async {
    final repo = FakeSupervisorRepository()..planValue = plan(id: 'p9');
    final container = _container(repo);
    container.listen(planDetailProvider('p9'), (_, _) {});

    final value = await container.read(planDetailProvider('p9').future);
    expect(value.id, 'p9');
  });

  test('planEtaProvider devuelve el ETA del plan', () async {
    final repo = FakeSupervisorRepository()
      ..planEtaValue = planEtaData(planId: 'p9', stops: [stopEta(sequence: 1)]);
    final container = _container(repo);
    container.listen(planEtaProvider('p9'), (_, _) {});

    final value = await container.read(planEtaProvider('p9').future);
    expect(value.planId, 'p9');
    expect(value.stops, hasLength(1));
  });

  test('vehicleSummaryProvider devuelve el resumen por vehículo', () async {
    final repo = FakeSupervisorRepository()
      ..vehicleSummaryValue = vehicleSummary(vehicleId: 'CAM-1');
    final container = _container(repo);
    container.listen(vehicleSummaryProvider('CAM-1'), (_, _) {});

    final value = await container.read(vehicleSummaryProvider('CAM-1').future);
    expect(value.vehicleId, 'CAM-1');
  });
}
