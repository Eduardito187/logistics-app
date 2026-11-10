// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/widgets.dart';
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

  int streamCalls = 0;

  @override
  Stream<GpsFix> stream({int distanceFilterMeters = 20}) {
    streamCalls++;
    return fixes.stream;
  }
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

// Simulan el paso a segundo/primer plano respetando la máquina de estados de
// AppLifecycleListener (resumed → inactive → hidden → paused y vuelta).
Future<void> _toBackground() async {
  final b = WidgetsBinding.instance;
  b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  b.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await pumpEventQueue();
}

Future<void> _toForeground() async {
  final b = WidgetsBinding.instance;
  b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await pumpEventQueue();
}

void main() {
  // El servicio observa el ciclo de vida (AppLifecycleListener), que necesita el
  // WidgetsBinding; se inicializa para poder simular primer/segundo plano.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Dejar el ciclo de vida en "primer plano" antes de cada test (un test
    // previo pudo dejarlo en paused); sin listener activo no dispara asserts.
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
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

  test(
    'start activa el rastreo SIN levantar el servicio (en primer plano)',
    () async {
      final container = _container(_FakeLocationService());

      final ok = await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');

      expect(ok, isTrue);
      // En primer plano NO se levanta el foreground service → sin notificación.
      expect(_platform.starts, 0);
      final state = container.read(truckTrackingProvider);
      expect(state.active, isTrue);
      expect(state.shipmentId, 'SHP-1');
      expect(state.sent, 0);
    },
  );

  test(
    'notificación fantasma: a segundo plano levanta el servicio; al volver lo baja',
    () async {
      final container = _container(_FakeLocationService());
      await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');
      expect(_platform.starts, 0); // primer plano: sin servicio ni notificación

      // App a segundo plano → se levanta el servicio (con su notificación).
      await _toBackground();
      expect(_platform.running, isTrue);
      expect(_platform.starts, 1);

      // De vuelta al primer plano → se baja (desaparece la notificación).
      await _toForeground();
      expect(_platform.running, isFalse);
    },
  );

  test('sin rastreo activo, cambiar de plano NO levanta el servicio', () async {
    final container = _container(_FakeLocationService());
    container.read(truckTrackingProvider); // construye el notifier (listener)

    await _toBackground();

    expect(_platform.starts, 0);
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

    expect(location.streamCalls, 1); // no se abrió otro stream de GPS
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

    // En primer plano no había servicio corriendo; lo que importa es que el
    // rastreo queda inactivo y deja de encolar posiciones.
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

    expect(container.read(truckTrackingProvider).active, isFalse);
  });

  test(
    'stopOrphanedService baja un servicio huérfano (estado inactivo)',
    () async {
      final container = _container(_FakeLocationService());
      // Simula un foreground service que sobrevivió a un reinicio: corriendo en el
      // SO, pero con el estado en memoria limpio (inactivo).
      _platform.running = true;
      expect(container.read(truckTrackingProvider).active, isFalse);

      await container
          .read(truckTrackingProvider.notifier)
          .stopOrphanedService();

      expect(_platform.running, isFalse);
      expect(_platform.stops, 1);
    },
  );

  test(
    'dos start a la vez: un solo servicio y un solo stream de GPS',
    () async {
      final location = _FakeLocationService();
      final container = _container(location);
      final notifier = container.read(truckTrackingProvider.notifier);

      final results = await Future.wait([
        notifier.start(shipmentId: 'A'),
        notifier.start(shipmentId: 'B'),
      ]);

      expect(results, [isTrue, isTrue]);
      // Un solo stream de GPS (en primer plano no se levanta el servicio).
      expect(location.streamCalls, 1);
      expect(_platform.starts, 0);
      // Gana el último envío pedido.
      expect(container.read(truckTrackingProvider).shipmentId, 'B');
    },
  );
}
