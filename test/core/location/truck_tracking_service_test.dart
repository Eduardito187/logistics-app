// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Rastreo del camión (Notifier). El foreground service se reemplaza por su
// PlatformInterface, el GPS por un stream controlado y la cola offline por un
// doble que registra lo encolado: así se cubre start/re-apuntar/stop/_onFix
// sin dispositivo.

class _FakeLocationService extends LocationService {
  bool background = true;
  final StreamController<GpsFix> fixes = StreamController<GpsFix>.broadcast();

  @override
  Future<bool> ensureBackgroundPermission() async => background;

  @override
  Stream<GpsFix> stream({int distanceFilterMeters = 20}) => fixes.stream;
}

class _FakeForegroundTask extends FlutterForegroundTaskPlatform
    with MockPlatformInterfaceMixin {
  bool running = false;
  bool failStart = false;
  int starts = 0;
  int stops = 0;
  NotificationPermission permission = NotificationPermission.granted;
  int permissionRequests = 0;

  @override
  Future<void> startService({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
    int? serviceId,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    List<NotificationButton>? notificationButtons,
    String? notificationInitialRoute,
    Function? callback,
  }) async {
    starts++;
    if (failStart) throw StateError('el sistema rechazó el servicio');
    running = true;
  }

  @override
  Future<void> stopService() async {
    stops++;
    running = false;
  }

  @override
  Future<bool> get isRunningService async => running;

  @override
  Future<NotificationPermission> checkNotificationPermission() async =>
      permission;

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    permissionRequests++;
    return NotificationPermission.granted;
  }
}

class _FakeQueue implements OfflineQueue {
  final List<({String kind, Map<String, Object?> payload, String label})>
  submitted = [];

  @override
  Future<SubmitOutcome> submit({
    required String kind,
    required Map<String, Object?> payload,
    required String label,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    submitted.add((kind: kind, payload: payload, label: label));
    return SubmitOutcome.queued;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late _FakeForegroundTask _platform;
late _FakeQueue _queue;

ProviderContainer _container(_FakeLocationService location) {
  final container = ProviderContainer(
    overrides: [
      locationServiceProvider.overrideWithValue(location),
      offlineQueueProvider.overrideWithValue(_queue),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    _platform = _FakeForegroundTask();
    FlutterForegroundTaskPlatform.instance = _platform;
    _queue = _FakeQueue();
    FlutterForegroundTask.resetStatic();
    // Sin espera real de 5 s al estado del servicio: el fake responde al toque.
    FlutterForegroundTask.skipServiceResponseCheck = true;
  });

  test('estado inicial: inactivo, sin envío, 0 enviados', () {
    final container = _container(_FakeLocationService());
    final state = container.read(truckTrackingProvider);
    expect(state.active, isFalse);
    expect(state.shipmentId, isNull);
    expect(state.sent, 0);
    expect(state.lastFix, isNull);
  });

  test(
    'start devuelve false y no activa si falta el permiso "siempre"',
    () async {
      final location = _FakeLocationService()..background = false;
      final container = _container(location);

      final ok = await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');

      expect(ok, isFalse);
      expect(_platform.starts, 0);
      final state = container.read(truckTrackingProvider);
      expect(state.active, isFalse);
      expect(state.shipmentId, isNull);
    },
  );

  test('start levanta el servicio y activa el rastreo del envío', () async {
    final container = _container(_FakeLocationService());

    final ok = await container
        .read(truckTrackingProvider.notifier)
        .start(shipmentId: 'SHP-1');

    expect(ok, isTrue);
    expect(_platform.starts, 1);
    final state = container.read(truckTrackingProvider);
    expect(state.active, isTrue);
    expect(state.shipmentId, 'SHP-1');
    expect(state.sent, 0);
  });

  test('pide el permiso de notificación solo si no está concedido', () async {
    final container = _container(_FakeLocationService());
    await container.read(truckTrackingProvider.notifier).start(shipmentId: 'A');
    expect(_platform.permissionRequests, 0);

    await container.read(truckTrackingProvider.notifier).stop();
    _platform.permission = NotificationPermission.denied;
    await container.read(truckTrackingProvider.notifier).start(shipmentId: 'B');
    expect(_platform.permissionRequests, 1);
  });

  test('si el servicio no arranca devuelve false y no se activa', () async {
    _platform.failStart = true;
    final container = _container(_FakeLocationService());

    final ok = await container
        .read(truckTrackingProvider.notifier)
        .start(shipmentId: 'SHP-1');

    expect(ok, isFalse);
    expect(container.read(truckTrackingProvider).active, isFalse);
  });

  test('cada fix se encola como ingestTruckPosition con el envío', () async {
    final location = _FakeLocationService();
    final container = _container(location);
    await container
        .read(truckTrackingProvider.notifier)
        .start(shipmentId: 'SHP-1');

    location.fixes.add(const GpsFix(lat: -16.5, lng: -68.1));
    await pumpEventQueue();

    final sent = _queue.submitted.single;
    expect(sent.kind, 'ingestTruckPosition');
    expect(sent.payload['@shipmentId'], 'SHP-1');
    expect(sent.payload['lat'], -16.5);
    expect(sent.payload['lng'], -68.1);
    expect(sent.label, 'GPS · SHP-1');
    final state = container.read(truckTrackingProvider);
    expect(state.lastFix?.lat, -16.5);
    expect(state.sent, 1);
  });

  test('start estando activo re-apunta el envío sin reiniciar', () async {
    final location = _FakeLocationService();
    final container = _container(location);
    final notifier = container.read(truckTrackingProvider.notifier);
    await notifier.start(shipmentId: 'SHP-1');

    expect(await notifier.start(shipmentId: 'SHP-2'), isTrue);
    location.fixes.add(const GpsFix(lat: 1, lng: 2));
    await pumpEventQueue();

    expect(_platform.starts, 1); // no se levantó otro servicio
    expect(container.read(truckTrackingProvider).shipmentId, 'SHP-2');
    expect(_queue.submitted.single.payload['@shipmentId'], 'SHP-2');
  });

  test(
    'fixes seguidos (< minFixInterval) se descartan: 1 fila, 1 POST',
    () async {
      final location = _FakeLocationService();
      final container = _container(location);
      await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');

      location.fixes
        ..add(const GpsFix(lat: 1, lng: 1))
        ..add(const GpsFix(lat: 2, lng: 2))
        ..add(const GpsFix(lat: 3, lng: 3));
      await pumpEventQueue();

      expect(TruckTrackingService.minFixInterval, const Duration(seconds: 10));
      expect(_queue.submitted, hasLength(1));
      expect(_queue.submitted.single.payload['lat'], 1);
      // El estado tampoco se reescribe con las lecturas descartadas.
      expect(container.read(truckTrackingProvider).lastFix?.lat, 1);
    },
  );

  test('stop baja el servicio y deja de encolar posiciones', () async {
    final location = _FakeLocationService();
    final container = _container(location);
    final notifier = container.read(truckTrackingProvider.notifier);
    await notifier.start(shipmentId: 'SHP-1');

    await notifier.stop();
    location.fixes.add(const GpsFix(lat: 1, lng: 2));
    await pumpEventQueue();

    expect(_platform.stops, 1);
    expect(container.read(truckTrackingProvider).active, isFalse);
    expect(_queue.submitted, isEmpty);
  });

  test('cerrar sesión detiene el rastreo activo', () async {
    // signOut borra el token del secure storage: en memoria para el test.
    FlutterSecureStorage.setMockInitialValues({});
    final container = _container(_FakeLocationService());
    container.read(sessionProvider.notifier).devSignIn(UserRole.driver);
    await container
        .read(truckTrackingProvider.notifier)
        .start(shipmentId: 'SHP-1');

    await container.read(sessionProvider.notifier).signOut();
    await pumpEventQueue();

    expect(_platform.stops, 1);
    expect(container.read(truckTrackingProvider).active, isFalse);
  });
}
