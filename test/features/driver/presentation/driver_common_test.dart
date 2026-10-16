import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/presentation/driver_common.dart';

// Helpers de formato puros de driver_common (sin red/GPS).

void main() {
  group('formatMoneyCents', () {
    test('formatea centavos con dos decimales y moneda', () {
      expect(formatMoneyCents(123450, 'BOB'), 'BOB 1234.50');
    });

    test('cero', () {
      expect(formatMoneyCents(0, 'BOB'), 'BOB 0.00');
    });

    test('redondea a dos decimales', () {
      expect(formatMoneyCents(99, 'USD'), 'USD 0.99');
    });
  });

  group('formatDate', () {
    test('yyyy-MM-dd con padding de mes y día', () {
      expect(formatDate(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('mes y día de dos dígitos', () {
      expect(formatDate(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('formatTime', () {
    test('HH:mm con padding', () {
      expect(formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('medianoche', () {
      expect(formatTime(DateTime(2026, 1, 1, 0, 0)), '00:00');
    });

    test('hora avanzada', () {
      expect(formatTime(DateTime(2026, 1, 1, 23, 59)), '23:59');
    });
  });
}
