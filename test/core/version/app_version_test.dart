import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/version/app_version.dart';

void main() {
  group('AppVersion.tryParse', () {
    test('formatos válidos', () {
      expect(AppVersion.tryParse('1.2.3'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('1.2'), const AppVersion(1, 2));
      expect(AppVersion.tryParse('2'), const AppVersion(2));
      expect(AppVersion.tryParse(' v1.4.0 '), const AppVersion(1, 4));
      expect(AppVersion.tryParse('1.2.3+45'), const AppVersion(1, 2, 3));
      expect(AppVersion.tryParse('1.2.3-rc.1'), const AppVersion(1, 2, 3));
    });

    test('inválidos devuelven null', () {
      for (final raw in [null, '', 'abc', '1.x', '1.2.3.4', '.1']) {
        expect(AppVersion.tryParse(raw), isNull, reason: '$raw');
      }
    });
  });

  test('comparación numérica, no lexicográfica', () {
    expect(const AppVersion(1, 9) < const AppVersion(1, 10), isTrue);
    expect(const AppVersion(1, 10) < const AppVersion(1, 9), isFalse);
    expect(const AppVersion(2) < const AppVersion(1, 99, 99), isFalse);
    expect(const AppVersion(1, 2, 3) < const AppVersion(1, 2, 4), isTrue);
    expect(const AppVersion(1, 2, 3) < const AppVersion(1, 2, 3), isFalse);
    expect(const AppVersion(1, 2, 3).toString(), '1.2.3');
  });
}
