import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/export.dart';
import 'package:logistics_app/features/driver/domain/odometer_check.dart';

// El odómetro solo avanza: `odometerBelowLast` devuelve el mayor km registrado
// si la nueva lectura es MENOR (retrocede), o null si es válida.

OdometerReading _reading(int km) => OdometerReading(
  id: 'r$km',
  vehicleId: 'v1',
  km: km,
  source: OdometerReadingSource.manual,
  readAt: DateTime(2026, 11, 11),
);

void main() {
  test('sin lecturas previas => válido (null)', () {
    expect(odometerBelowLast(100, const []), isNull);
  });

  test('mayor que el último => válido (null)', () {
    expect(odometerBelowLast(200, [_reading(150)]), isNull);
  });

  test('igual al último => válido (null, no retrocede)', () {
    expect(odometerBelowLast(150, [_reading(150)]), isNull);
  });

  test('menor que el último => devuelve el mayor km', () {
    expect(odometerBelowLast(120, [_reading(150)]), 150);
  });

  test('toma el MAYOR de varias lecturas (no la primera)', () {
    expect(
      odometerBelowLast(160, [_reading(150), _reading(180), _reading(120)]),
      180,
    );
  });
}
