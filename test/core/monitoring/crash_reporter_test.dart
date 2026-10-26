import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/monitoring/crash_reporter.dart';

void main() {
  group('sanitizeBreadcrumb', () {
    test('deja pasar eventos técnicos', () {
      expect(sanitizeBreadcrumb('scan.load.ok'), 'scan.load.ok');
      expect(
        sanitizeBreadcrumb('nav.push /driver/route'),
        'nav.push /driver/route',
      );
    });

    test('enmascara ids numéricos, ULID y UUID en paths', () {
      expect(
        sanitizeBreadcrumb('nav.push /shipments/123456'),
        'nav.push /shipments/:id',
      );
      expect(
        sanitizeBreadcrumb('nav.push /orders/01HZX3K9V8Q2M4N6P8R0T2V4W6'),
        'nav.push /orders/:id',
      );
      expect(
        sanitizeBreadcrumb('nav.push /d/123e4567-e89b-12d3-a456-426614174000'),
        'nav.push /d/:id',
      );
    });

    test('reemplaza caracteres fuera del set (emails, acentos)', () {
      final out = sanitizeBreadcrumb('login juan@dismac.com Ñandú');
      expect(out, isNot(contains('@')));
      expect(RegExp(r'^[a-z0-9_.:/\- ]*$').hasMatch(out), isTrue);
    });

    test('corta a 120 caracteres', () {
      expect(sanitizeBreadcrumb('a' * 500).length, 120);
    });
  });

  group('NoopCrashReporter', () {
    test('es inerte y nunca lanza', () async {
      const reporter = NoopCrashReporter();
      expect(reporter.isEnabled, isFalse);
      reporter.breadcrumb('x');
      await reporter.recordError(Exception('x'), StackTrace.current);
      await reporter.recordFlutterError(
        FlutterErrorDetails(exception: Exception('x')),
      );
      await reporter.setCustomKey('k', null);
      await reporter.setUser(
        const CrashUserContext(userId: 'u_1', role: 'chofer'),
      );
      await reporter.setUser(null);
    });

    test('es el valor por defecto de crashReporterProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(crashReporterProvider), isA<NoopCrashReporter>());
    });
  });

  test('sanitizeBreadcrumb acota entradas enormes', () {
    final out = sanitizeBreadcrumb('nav.push /${'a' * 100000}');
    expect(out.length, lessThanOrEqualTo(120));
  });
}
