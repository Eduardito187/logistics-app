import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_urgency.dart';

// Orden de urgencia (0 = más crítico) usado para ordenar la lista de
// mantenimientos por vencer de más a menos urgente.

void main() {
  test('order asigna 0/1/2 de más a menos urgente', () {
    expect(DueMaintenanceUrgency.overdue.order, 0);
    expect(DueMaintenanceUrgency.dueSoon.order, 1);
    expect(DueMaintenanceUrgency.scheduled.order, 2);
  });

  test('ordenar por order deja lo vencido primero', () {
    final list = [
      DueMaintenanceUrgency.scheduled,
      DueMaintenanceUrgency.overdue,
      DueMaintenanceUrgency.dueSoon,
    ]..sort((a, b) => a.order.compareTo(b.order));

    expect(list, [
      DueMaintenanceUrgency.overdue,
      DueMaintenanceUrgency.dueSoon,
      DueMaintenanceUrgency.scheduled,
    ]);
  });

  test('el enum tiene exactamente tres valores', () {
    expect(DueMaintenanceUrgency.values, hasLength(3));
  });
}
