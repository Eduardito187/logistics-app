import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/domain/entities/due_maintenance_item.dart';

// Entidad del cliente DueMaintenanceItem: parseo tolerante del objeto libre del
// backend y su invariante de urgencia derivada.

void main() {
  group('DueMaintenanceItem.fromMap', () {
    test('parsea todos los campos tipados', () {
      final item = DueMaintenanceItem.fromMap({
        'vehicle_id': 'v1',
        'plate': 'ABC-123',
        'service_kind': 'oil_change',
        'next_due_at': '2026-11-01T00:00:00Z',
        'next_due_km': 50000,
        'current_km': 49800,
        'remaining_km': 200,
        'remaining_days': 17,
        'overdue': false,
      });

      expect(item.vehicleId, 'v1');
      expect(item.plate, 'ABC-123');
      expect(item.serviceKind, MaintenancePlanServiceKind.oilChange);
      expect(item.nextDueAt, DateTime.parse('2026-11-01T00:00:00Z'));
      expect(item.nextDueKm, 50000);
      expect(item.currentKm, 49800);
      expect(item.remainingKm, 200);
      expect(item.remainingDays, 17);
      expect(item.overdue, isFalse);
    });

    test('usa vehicle_plate como fallback de plate', () {
      final item = DueMaintenanceItem.fromMap({'vehicle_plate': 'XYZ-999'});
      expect(item.plate, 'XYZ-999');
    });

    test('_asInt tolera int, double, string y null', () {
      final item = DueMaintenanceItem.fromMap({
        'next_due_km': 1000, // int
        'remaining_km': 12.7, // double -> redondea a 13
        'remaining_days': '5', // string -> 5
        'current_km': 'no-numero', // no parseable -> null
      });
      expect(item.nextDueKm, 1000);
      expect(item.remainingKm, 13);
      expect(item.remainingDays, 5);
      expect(item.currentKm, isNull);
    });

    test('_asDate devuelve null ante valor no-string o fecha inválida', () {
      final item = DueMaintenanceItem.fromMap({'next_due_at': 12345});
      expect(item.nextDueAt, isNull);
      final bad = DueMaintenanceItem.fromMap({'next_due_at': 'no-fecha'});
      expect(bad.nextDueAt, isNull);
    });

    test('service_kind no-string queda en null', () {
      final item = DueMaintenanceItem.fromMap({'service_kind': 42});
      expect(item.serviceKind, isNull);
    });

    group('derivación de overdue cuando no viene explícito', () {
      test('remaining_days negativo => overdue', () {
        final item = DueMaintenanceItem.fromMap({'remaining_days': -1});
        expect(item.overdue, isTrue);
      });

      test('remaining_km negativo => overdue', () {
        final item = DueMaintenanceItem.fromMap({'remaining_km': -5});
        expect(item.overdue, isTrue);
      });

      test('sin datos negativos => no overdue', () {
        final item = DueMaintenanceItem.fromMap({'remaining_days': 3});
        expect(item.overdue, isFalse);
      });

      test('bool overdue explícito tiene prioridad', () {
        final item = DueMaintenanceItem.fromMap({
          'overdue': true,
          'remaining_days': 30,
        });
        expect(item.overdue, isTrue);
      });
    });
  });

  group('urgency', () {
    test('overdue explícito => overdue', () {
      const item = DueMaintenanceItem(overdue: true);
      expect(item.urgency, DueMaintenanceUrgency.overdue);
    });

    test('remaining_days <= 0 => overdue', () {
      const item = DueMaintenanceItem(overdue: false, remainingDays: 0);
      expect(item.urgency, DueMaintenanceUrgency.overdue);
    });

    test('remaining_km <= 0 => overdue', () {
      const item = DueMaintenanceItem(overdue: false, remainingKm: 0);
      expect(item.urgency, DueMaintenanceUrgency.overdue);
    });

    test('remaining_days <= 7 => dueSoon', () {
      const item = DueMaintenanceItem(overdue: false, remainingDays: 7);
      expect(item.urgency, DueMaintenanceUrgency.dueSoon);
    });

    test('remaining_km <= 500 => dueSoon', () {
      const item = DueMaintenanceItem(overdue: false, remainingKm: 500);
      expect(item.urgency, DueMaintenanceUrgency.dueSoon);
    });

    test('margen amplio => scheduled', () {
      const item = DueMaintenanceItem(
        overdue: false,
        remainingDays: 30,
        remainingKm: 5000,
      );
      expect(item.urgency, DueMaintenanceUrgency.scheduled);
    });

    test('sin remaining_days usa nextDueAt para derivar los días', () {
      // Fecha ya pasada: días <= 0 => overdue.
      final past = DueMaintenanceItem(
        overdue: false,
        nextDueAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(past.urgency, DueMaintenanceUrgency.overdue);

      // Dentro de 3 días => dueSoon.
      final soon = DueMaintenanceItem(
        overdue: false,
        nextDueAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(soon.urgency, DueMaintenanceUrgency.dueSoon);

      // Lejano => scheduled.
      final far = DueMaintenanceItem(
        overdue: false,
        nextDueAt: DateTime.now().add(const Duration(days: 60)),
      );
      expect(far.urgency, DueMaintenanceUrgency.scheduled);
    });

    test('sin ninguna señal => scheduled', () {
      const item = DueMaintenanceItem(overdue: false);
      expect(item.urgency, DueMaintenanceUrgency.scheduled);
    });
  });
}
