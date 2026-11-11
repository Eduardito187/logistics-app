import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/domain/route_km_today.dart';

// routeKmToday: km recorridos de la ruta del día = llegada − salida, tomando la
// lectura de salida y de llegada más recientes del mismo día. Nunca lanza.

OdometerReading _reading({
  required int km,
  required OdometerReadingSource source,
  required DateTime readAt,
  String id = 'r',
}) => OdometerReading(
  id: id,
  vehicleId: 'v1',
  km: km,
  source: source,
  readAt: readAt,
);

void main() {
  final now = DateTime(2026, 11, 11, 18, 30);

  group('routeKmToday', () {
    test('salida y llegada presentes → recorrido = llegada − salida', () {
      final readings = [
        _reading(
          km: 12050,
          source: OdometerReadingSource.arrival,
          readAt: DateTime(2026, 11, 11, 17, 0),
        ),
        _reading(
          km: 12000,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 11, 8, 0),
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.traveledKm, 50);
      expect(result.departureKm, 12000);
      expect(result.arrivalKm, 12050);
    });

    test('solo salida → traveledKm null pero conserva la salida', () {
      final readings = [
        _reading(
          km: 12000,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 11, 8, 0),
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.traveledKm, isNull);
      expect(result.departureKm, 12000);
      expect(result.arrivalKm, isNull);
    });

    test('ninguna lectura del día → todo null', () {
      final result = routeKmToday(const [], now);

      expect(result.traveledKm, isNull);
      expect(result.departureKm, isNull);
      expect(result.arrivalKm, isNull);
    });

    test('llegada menor que salida → traveledKm null (nunca negativo)', () {
      final readings = [
        _reading(
          km: 11990,
          source: OdometerReadingSource.arrival,
          readAt: DateTime(2026, 11, 11, 17, 0),
        ),
        _reading(
          km: 12000,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 11, 8, 0),
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.traveledKm, isNull);
      expect(result.departureKm, 12000);
      expect(result.arrivalKm, 11990);
    });

    test('lecturas de otro día se ignoran', () {
      final readings = [
        _reading(
          km: 11000,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 10, 8, 0),
        ),
        _reading(
          km: 11080,
          source: OdometerReadingSource.arrival,
          readAt: DateTime(2026, 11, 10, 17, 0),
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.traveledKm, isNull);
      expect(result.departureKm, isNull);
      expect(result.arrivalKm, isNull);
    });

    test('toma la lectura más reciente de cada tipo del día', () {
      final readings = [
        _reading(
          km: 12000,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 11, 8, 0),
          id: 'dep-old',
        ),
        // Salida corregida más tarde: debe ganar.
        _reading(
          km: 12010,
          source: OdometerReadingSource.departure,
          readAt: DateTime(2026, 11, 11, 8, 30),
          id: 'dep-new',
        ),
        _reading(
          km: 12100,
          source: OdometerReadingSource.arrival,
          readAt: DateTime(2026, 11, 11, 17, 0),
          id: 'arr',
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.departureKm, 12010);
      expect(result.arrivalKm, 12100);
      expect(result.traveledKm, 90);
    });

    test('otras fuentes (manual/refuel) se ignoran', () {
      final readings = [
        _reading(
          km: 12345,
          source: OdometerReadingSource.manual,
          readAt: DateTime(2026, 11, 11, 10, 0),
        ),
        _reading(
          km: 12400,
          source: OdometerReadingSource.refuel,
          readAt: DateTime(2026, 11, 11, 12, 0),
        ),
      ];

      final result = routeKmToday(readings, now);

      expect(result.traveledKm, isNull);
      expect(result.departureKm, isNull);
      expect(result.arrivalKm, isNull);
    });
  });
}
