import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/monitoring/crash_reporter.dart';
import 'package:logistics_app/core/monitoring/crash_reporting_init.dart';
import 'package:logistics_app/core/monitoring/crashlytics_crash_reporter.dart';

import 'fake_crash_reporter.dart';

/// Crashlytics falso: sin plataforma, registra las llamadas.
class FakeCrashlytics extends Fake implements FirebaseCrashlytics {
  bool? collectionEnabled;
  bool throwOnLog = false;
  String? userId;
  final Map<String, Object> keys = {};
  final List<String> logs = [];
  final List<({Object? error, bool fatal, Object? reason})> errors = [];
  final List<({FlutterErrorDetails details, bool fatal})> flutterErrors = [];

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async =>
      collectionEnabled = enabled;

  @override
  Future<void> setUserIdentifier(String identifier) async =>
      userId = identifier;

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      keys[key] = value;

  @override
  Future<void> log(String message) async {
    if (throwOnLog) throw StateError('plugin roto');
    logs.add(message);
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool? printDetails,
    bool fatal = false,
  }) async => errors.add((error: exception, fatal: fatal, reason: reason));

  @override
  Future<void> recordFlutterError(
    FlutterErrorDetails flutterErrorDetails, {
    bool fatal = false,
  }) async => flutterErrors.add((details: flutterErrorDetails, fatal: fatal));

  @override
  Future<void> recordFlutterFatalError(
    FlutterErrorDetails flutterErrorDetails,
  ) => recordFlutterError(flutterErrorDetails, fatal: true);
}

void main() {
  late FakeCrashlytics crashlytics;
  late CrashlyticsCrashReporter reporter;

  setUp(() {
    crashlytics = FakeCrashlytics();
    reporter = CrashlyticsCrashReporter(crashlytics, enabled: true);
  });

  group('CrashlyticsCrashReporter', () {
    test('setUser setea id seudónimo y claves de contexto', () async {
      await reporter.setUser(
        const CrashUserContext(
          userId: 'u_abc',
          role: 'tienda',
          storeNodeId: 'node-1',
          vehicleId: 'veh-9',
        ),
      );
      expect(crashlytics.userId, 'u_abc');
      expect(crashlytics.keys[CrashKeys.role], 'tienda');
      expect(crashlytics.keys[CrashKeys.storeNodeId], 'node-1');
      expect(crashlytics.keys[CrashKeys.vehicleId], 'veh-9');
    });

    test('setUser(null) limpia id y claves al cerrar sesión', () async {
      await reporter.setUser(
        const CrashUserContext(userId: 'u_abc', role: 'chofer'),
      );
      await reporter.setUser(null);
      expect(crashlytics.userId, '');
      expect(crashlytics.keys[CrashKeys.role], '');
      expect(crashlytics.keys[CrashKeys.storeNodeId], '');
    });

    test('breadcrumb sanitiza antes de loguear', () {
      reporter.breadcrumb('nav.push /shipments/987654');
      expect(crashlytics.logs, ['nav.push /shipments/:id']);
    });

    test('recordError y recordFlutterError delegan con fatal', () async {
      await reporter.recordError(StateError('x'), null, reason: 'r');
      await reporter.recordFlutterError(
        FlutterErrorDetails(exception: Exception('f')),
        fatal: true,
      );
      expect(crashlytics.errors.single.reason, 'r');
      expect(crashlytics.errors.single.fatal, isFalse);
      expect(crashlytics.flutterErrors.single.fatal, isTrue);
    });

    test('setCustomKey convierte null a vacío', () async {
      await reporter.setCustomKey('k', null);
      await reporter.setCustomKey('n', 3);
      expect(crashlytics.keys['k'], '');
      expect(crashlytics.keys['n'], 3);
    });

    test('un fallo del plugin no se propaga', () {
      crashlytics.throwOnLog = true;
      expect(() => reporter.breadcrumb('x'), returnsNormally);
    });
  });

  group('initCrashReporting', () {
    test('sin credenciales de Firebase devuelve no-op', () async {
      final result = await initCrashReporting(
        initFirebase: () async => false,
        crashlytics: () => fail('no debe tocar Crashlytics'),
      );
      expect(result, isA<NoopCrashReporter>());
    });

    test('con Firebase usa Crashlytics y respeta la colección', () async {
      final result = await initCrashReporting(
        initFirebase: () async => true,
        crashlytics: () => crashlytics,
        collectionEnabled: false,
        installHandlers: false,
      );
      expect(result, isA<CrashlyticsCrashReporter>());
      expect(result.isEnabled, isFalse);
      expect(crashlytics.collectionEnabled, isFalse);
      expect(crashlytics.keys[CrashKeys.env], isNotNull);
    });

    test('si Firebase falla al iniciar, no-op sin lanzar', () async {
      final result = await initCrashReporting(
        initFirebase: () async => throw StateError('sin google services'),
      );
      expect(result, isA<NoopCrashReporter>());
    });
  });

  group('installCrashHandlers', () {
    test('FlutterError.onError reporta como fatal y encadena el previo', () {
      final originalFlutter = FlutterError.onError;
      final dispatcher = PlatformDispatcher.instance;
      final originalPlatform = dispatcher.onError;
      addTearDown(() {
        FlutterError.onError = originalFlutter;
        dispatcher.onError = originalPlatform;
      });

      final previous = <FlutterErrorDetails>[];
      FlutterError.onError = previous.add;
      final fake = FakeCrashReporter();
      installCrashHandlers(fake);

      final details = FlutterErrorDetails(exception: Exception('boom'));
      FlutterError.onError!(details);
      expect(previous, [details]);
      expect(fake.flutterErrors, [details]);

      final handled = dispatcher.onError!(
        StateError('async'),
        StackTrace.empty,
      );
      expect(handled, isTrue);
      expect(fake.errors.single.fatal, isTrue);
    });
  });
}
