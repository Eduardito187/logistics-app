import '../../../core/api/models/alert.dart';
import '../../../core/api/models/plan.dart';
import '../../../core/api/models/plan_status.dart';
import '../../../core/api/models/shipment.dart';
import '../../../core/api/models/shipment_status.dart';

/// Métricas del día para el tablero del supervisor. Lógica pura (sin Flutter)
/// derivada de envíos, planes y alertas, para poder probarla con unit tests.
class DashboardMetrics {
  const DashboardMetrics({
    required this.received,
    required this.planned,
    required this.inExecution,
    required this.delivered,
    required this.failed,
    required this.cancelled,
    required this.activePlans,
    required this.openAlerts,
  });

  /// Envíos recibidos (aún sin planificar).
  final int received;

  /// Envíos planificados pero no en ruta.
  final int planned;

  /// Envíos en ruta (ejecución).
  final int inExecution;

  /// Entregas completadas con éxito.
  final int delivered;

  /// Entregas fallidas.
  final int failed;

  /// Envíos cancelados.
  final int cancelled;

  /// Planes publicados (rutas en curso).
  final int activePlans;

  /// Alertas de telemetría sin reconocer.
  final int openAlerts;

  /// Total de envíos del día.
  int get total =>
      received + planned + inExecution + delivered + failed + cancelled;

  /// Entregas ya resueltas (entregadas o fallidas).
  int get completed => delivered + failed;

  /// Pendientes de salir a ruta.
  int get pending => received + planned;

  /// Tasa de cumplimiento (entregadas / resueltas), `null` si aún no hay
  /// entregas resueltas para evitar dividir por cero.
  double? get fulfillmentRate => completed == 0 ? null : delivered / completed;

  /// Construye las métricas agregando las tres fuentes del día.
  factory DashboardMetrics.from({
    required List<Shipment> shipments,
    required List<Plan> plans,
    required List<Alert> alerts,
  }) {
    var received = 0;
    var planned = 0;
    var inExecution = 0;
    var delivered = 0;
    var failed = 0;
    var cancelled = 0;

    for (final shipment in shipments) {
      switch (shipment.status) {
        case ShipmentStatus.received:
          received++;
        case ShipmentStatus.planned:
          planned++;
        case ShipmentStatus.inExecution:
          inExecution++;
        case ShipmentStatus.delivered:
          delivered++;
        case ShipmentStatus.failed:
          failed++;
        case ShipmentStatus.cancelled:
          cancelled++;
        case ShipmentStatus.$unknown:
          break;
      }
    }

    final activePlans = plans
        .where((p) => p.status == PlanStatus.published)
        .length;
    final openAlerts = alerts.where((a) => a.acknowledgedAt == null).length;

    return DashboardMetrics(
      received: received,
      planned: planned,
      inExecution: inExecution,
      delivered: delivered,
      failed: failed,
      cancelled: cancelled,
      activePlans: activePlans,
      openAlerts: openAlerts,
    );
  }
}
