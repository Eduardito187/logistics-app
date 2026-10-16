import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/address_confidence_level.dart';
import 'package:logistics_app/core/api/models/alert.dart';
import 'package:logistics_app/core/api/models/alert_severity.dart';
import 'package:logistics_app/core/api/models/alert_type.dart';
import 'package:logistics_app/core/api/models/order_source.dart';
import 'package:logistics_app/core/api/models/plan.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/features/supervisor/domain/dashboard_metrics.dart';

// Agregación pura de las métricas del tablero del supervisor. Se arman
// entradas de ejemplo y se verifican los conteos derivados.

Shipment _shipment(ShipmentStatus status) => Shipment(
  id: 's-${status.name}',
  source: OrderSource.sap,
  externalId: 'EXT',
  customerName: 'Cliente',
  addressText: 'Calle 1',
  addressConfidenceScore: 80,
  addressConfidenceLevel: AddressConfidenceLevel.high,
  status: status,
  lines: const [],
);

Plan _plan(PlanStatus status) => Plan(
  id: 'p-${status.name}',
  planDate: DateTime(2026, 3, 9),
  vehicleId: 'v1',
  status: status,
  stops: const [],
);

Alert _alert({DateTime? acknowledgedAt}) => Alert(
  id: 'a-${acknowledgedAt == null ? 'open' : 'ack'}',
  vehicleId: 'v1',
  type: AlertType.speeding,
  severity: AlertSeverity.warning,
  detail: null,
  occurredAt: DateTime(2026, 3, 9),
  acknowledgedAt: acknowledgedAt,
);

void main() {
  group('DashboardMetrics.from', () {
    test('cuenta los envíos por estado', () {
      final metrics = DashboardMetrics.from(
        shipments: [
          _shipment(ShipmentStatus.received),
          _shipment(ShipmentStatus.received),
          _shipment(ShipmentStatus.planned),
          _shipment(ShipmentStatus.inExecution),
          _shipment(ShipmentStatus.delivered),
          _shipment(ShipmentStatus.delivered),
          _shipment(ShipmentStatus.delivered),
          _shipment(ShipmentStatus.failed),
          _shipment(ShipmentStatus.cancelled),
        ],
        plans: const [],
        alerts: const [],
      );

      expect(metrics.received, 2);
      expect(metrics.planned, 1);
      expect(metrics.inExecution, 1);
      expect(metrics.delivered, 3);
      expect(metrics.failed, 1);
      expect(metrics.cancelled, 1);
      expect(metrics.total, 9);
    });

    test('ignora envíos con estado desconocido en el total', () {
      final metrics = DashboardMetrics.from(
        shipments: [
          _shipment(ShipmentStatus.delivered),
          _shipment(ShipmentStatus.$unknown),
        ],
        plans: const [],
        alerts: const [],
      );

      expect(metrics.delivered, 1);
      expect(metrics.total, 1);
    });

    test('solo los planes publicados cuentan como rutas activas', () {
      final metrics = DashboardMetrics.from(
        shipments: const [],
        plans: [
          _plan(PlanStatus.published),
          _plan(PlanStatus.published),
          _plan(PlanStatus.draft),
          _plan(PlanStatus.proposed),
        ],
        alerts: const [],
      );

      expect(metrics.activePlans, 2);
    });

    test('solo las alertas sin reconocer cuentan como abiertas', () {
      final metrics = DashboardMetrics.from(
        shipments: const [],
        plans: const [],
        alerts: [
          _alert(),
          _alert(),
          _alert(acknowledgedAt: DateTime(2026, 3, 9, 10)),
        ],
      );

      expect(metrics.openAlerts, 2);
    });
  });

  group('métricas derivadas', () {
    test('completed, pending y total se derivan de los conteos', () {
      const metrics = DashboardMetrics(
        received: 3,
        planned: 2,
        inExecution: 1,
        delivered: 4,
        failed: 1,
        cancelled: 0,
        activePlans: 2,
        openAlerts: 1,
      );

      expect(metrics.completed, 5); // delivered + failed
      expect(metrics.pending, 5); // received + planned
      expect(metrics.total, 11);
    });

    test('fulfillmentRate es entregadas/resueltas', () {
      const metrics = DashboardMetrics(
        received: 0,
        planned: 0,
        inExecution: 0,
        delivered: 3,
        failed: 1,
        cancelled: 0,
        activePlans: 0,
        openAlerts: 0,
      );

      expect(metrics.fulfillmentRate, closeTo(0.75, 1e-9));
    });

    test('fulfillmentRate es null cuando aún no hay entregas resueltas', () {
      const metrics = DashboardMetrics(
        received: 5,
        planned: 0,
        inExecution: 0,
        delivered: 0,
        failed: 0,
        cancelled: 0,
        activePlans: 0,
        openAlerts: 0,
      );

      expect(metrics.fulfillmentRate, isNull);
    });
  });
}
