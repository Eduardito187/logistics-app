// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' show LocationAccuracy;
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/live_updates/route_live_notification.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/location/truck_tracking_service.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/power/power_channel.dart';
import 'package:logistics_app/core/power/power_status.dart';
import 'package:logistics_app/core/power/power_status_notifier.dart';
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

  /// Perfiles con los que se pidió el stream (GPS adaptativo).
  final List<TrackingProfile?> profiles = [];

  @override
  Stream<GpsFix> stream({
    int distanceFilterMeters = 20,
    TrackingProfile? profile,
  }) {
    streamCalls++;
    profiles.add(profile);
    return fixes.stream;
  }
}

class _FakeForegroundTask extends FlutterForegroundTaskPlatform
    with MockPlatformInterfaceMixin {
  bool running = false;
  bool failStart = false;
  int starts = 0;
  int stops = 0;
  int? serviceId;
  String? title;
  String? text;
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
    this.serviceId = serviceId;
    title = notificationTitle;
    text = notificationText;
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
late DateTime _now;

// Puntos en Santa Cruz: B está ~110 m al norte de A, C ~1,1 km.
const _a = GpsFix(lat: -17.7800, lng: -63.1800, accuracy: 10);
const _aJitter = GpsFix(lat: -17.78005, lng: -63.18003, accuracy: 10);
const _b = GpsFix(lat: -17.7790, lng: -63.1800, accuracy: 10);
const _c = GpsFix(lat: -17.7700, lng: -63.1800, accuracy: 10);

/// Canal de energía falso (ahorro de energía / batería configurable).
class _FakePowerChannel extends PowerChannel {
  _FakePowerChannel(this.status);

  PowerStatus status;

  @override
  Future<PowerStatus> read() async => status;
}

ProviderContainer _container(
  _FakeLocationService location, {
  PowerChannel? power,
}) {
  final container = ProviderContainer(
    overrides: [
      locationServiceProvider.overrideWithValue(location),
      offlineQueueProvider.overrideWithValue(_queue),
      if (power != null) powerChannelProvider.overrideWithValue(power),
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
    _now = DateTime(2026, 11, 11, 9);
    TruckTrackingService.clock = () => _now;
  });

  tearDown(() => TruckTrackingService.clock = DateTime.now);

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

  test(
    'una sola notificación: el servicio usa el id de la ruta en vivo y texto neutro',
    () async {
      final container = _container(_FakeLocationService());
      await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');
      expect(
        container.read(truckTrackingProvider).foregroundServiceRunning,
        isFalse,
      );

      await _toBackground();
      expect(_platform.serviceId, routeLiveNotificationId);
      expect(_platform.serviceId, 4120);
      expect(_platform.title, 'DisTrack');
      expect(_platform.text, isNot(contains('Sesión en curso')));
      expect(_platform.text, routeLiveFallbackText);
      // La ruta en vivo escucha este flag para publicar encima.
      expect(
        container.read(truckTrackingProvider).foregroundServiceRunning,
        isTrue,
      );

      await _toForeground();
      expect(
        container.read(truckTrackingProvider).foregroundServiceRunning,
        isFalse,
      );
    },
  );

  test('si el SO rechaza el servicio el flag queda en false', () async {
    _platform.failStart = true;
    final container = _container(_FakeLocationService());
    await container
        .read(truckTrackingProvider.notifier)
        .start(shipmentId: 'SHP-1');
    await _toBackground();
    expect(_platform.starts, 1);
    expect(
      container.read(truckTrackingProvider).foregroundServiceRunning,
      isFalse,
    );
  });

  test('stop baja el flag del servicio', () async {
    final container = _container(_FakeLocationService());
    final notifier = container.read(truckTrackingProvider.notifier);
    await notifier.start(shipmentId: 'SHP-1');
    await _toBackground();
    expect(
      container.read(truckTrackingProvider).foregroundServiceRunning,
      isTrue,
    );
    await notifier.stop();
    expect(
      container.read(truckTrackingProvider).foregroundServiceRunning,
      isFalse,
    );
  });

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

      expect(TruckTrackingService.minFixInterval, const Duration(seconds: 15));
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

  group('batería: GPS adaptativo y envío por lotes', () {
    Future<(ProviderContainer, _FakeLocationService)> started({
      PowerChannel? power,
    }) async {
      final location = _FakeLocationService();
      final container = _container(location, power: power);
      await container
          .read(truckTrackingProvider.notifier)
          .start(shipmentId: 'SHP-1');
      return (container, location);
    }

    Future<void> fixAt(
      _FakeLocationService location,
      GpsFix fix, {
      Duration after = Duration.zero,
    }) async {
      _now = _now.add(after);
      location.fixes.add(fix);
      await pumpEventQueue();
    }

    test('arranca en el perfil "en marcha" (GPS preciso, 15 s)', () async {
      final (container, location) = await started();
      final notifier = container.read(truckTrackingProvider.notifier);
      expect(notifier.profile, TrackingProfile.moving);
      expect(location.profiles.single, TrackingProfile.moving);
      expect(TrackingProfile.moving.accuracy, LocationAccuracy.high);
      expect(TrackingProfile.moving.interval, const Duration(seconds: 15));
    });

    test(
      'la primera posición sale ya; las siguientes se juntan en lote',
      () async {
        final (container, location) = await started();
        final notifier = container.read(truckTrackingProvider.notifier);

        await fixAt(location, _a);
        expect(_queue.submitted, hasLength(1)); // primera: inmediata

        await fixAt(location, _b, after: const Duration(seconds: 20));
        await fixAt(location, _c, after: const Duration(seconds: 20));
        // Juntadas en memoria: sin fila ni POST todavía (la radio duerme).
        expect(_queue.submitted, hasLength(1));
        expect(notifier.pendingBatch, 2);
        // El mapa igual ve la última posición.
        expect(container.read(truckTrackingProvider).lastFix?.lat, _c.lat);

        await notifier.flushNow();
        expect(_queue.submitted, hasLength(3));
        expect(_queue.submitted.map((e) => e.payload['lat']).toList(), [
          _a.lat,
          _b.lat,
          _c.lat,
        ]);
        expect(container.read(truckTrackingProvider).sent, 3);
      },
    );

    test('pasado el intervalo del lote, la próxima lectura lo envía', () async {
      final (container, location) = await started();
      await fixAt(location, _a);
      await fixAt(location, _b, after: const Duration(seconds: 20));
      expect(_queue.submitted, hasLength(1));
      // > 60 s desde el último envío: el lote sale con la lectura siguiente.
      await fixAt(location, _c, after: const Duration(seconds: 50));
      expect(_queue.submitted, hasLength(3));
      expect(container.read(truckTrackingProvider.notifier).pendingBatch, 0);
    });

    test('lecturas en el mismo lugar (jitter) no se encolan', () async {
      final (container, location) = await started();
      await fixAt(location, _a);
      await fixAt(location, _aJitter, after: const Duration(seconds: 20));
      await fixAt(location, _aJitter, after: const Duration(seconds: 20));
      await container.read(truckTrackingProvider.notifier).flushNow();
      expect(_queue.submitted, hasLength(1));
    });

    test(
      'quieto 3 min → perfil "detenido" (sin chip GPS) y vuelve al moverse',
      () async {
        final (container, location) = await started();
        final notifier = container.read(truckTrackingProvider.notifier);
        await fixAt(location, _a);

        _now = _now.add(const Duration(minutes: 3));
        notifier.checkStillness();
        await pumpEventQueue();
        expect(notifier.profile, TrackingProfile.stationary);
        expect(location.profiles.last, TrackingProfile.stationary);
        expect(TrackingProfile.stationary.accuracy, LocationAccuracy.medium);

        // Se mueve > 40 m: vuelve a "en marcha" con GPS preciso.
        await fixAt(location, _b, after: const Duration(seconds: 70));
        expect(notifier.profile, TrackingProfile.moving);
        expect(location.profiles.last, TrackingProfile.moving);
      },
    );

    test('detenido: el latido reenvía la última posición', () async {
      final (container, location) = await started();
      final notifier = container.read(truckTrackingProvider.notifier);
      await fixAt(location, _a);
      _now = _now.add(const Duration(minutes: 3));
      notifier.checkStillness();

      _now = _now.add(const Duration(minutes: 5));
      notifier.heartbeat();
      await pumpEventQueue();

      expect(_queue.submitted, hasLength(2));
      expect(_queue.submitted.last.payload['lat'], _a.lat);
    });

    test('ahorro de energía → perfil espaciado; al salir, normal', () async {
      final power = _FakePowerChannel(
        const PowerStatus(level: 80, powerSave: true),
      );
      final location = _FakeLocationService();
      final container = _container(location, power: power);
      // Lee el estado de energía antes de arrancar el rastreo.
      container.read(powerStatusProvider);
      await container.read(powerStatusProvider.notifier).refresh();
      final notifier = container.read(truckTrackingProvider.notifier);
      await notifier.start(shipmentId: 'SHP-1');
      expect(notifier.profile, TrackingProfile.movingSaving);

      power.status = const PowerStatus(level: 80);
      await container.read(powerStatusProvider.notifier).refresh();
      await pumpEventQueue();
      expect(notifier.profile, TrackingProfile.moving);
      expect(location.profiles.last, TrackingProfile.moving);
    });

    test('batería baja (< 20 %, sin cargar) también ahorra', () async {
      final power = _FakePowerChannel(const PowerStatus(level: 15));
      final location = _FakeLocationService();
      final container = _container(location, power: power);
      container.read(powerStatusProvider);
      await container.read(powerStatusProvider.notifier).refresh();
      final notifier = container.read(truckTrackingProvider.notifier);
      await notifier.start(shipmentId: 'SHP-1');
      expect(notifier.profile, TrackingProfile.movingSaving);
    });

    test('stop encola lo juntado antes de soltar el envío', () async {
      final (container, location) = await started();
      await fixAt(location, _a);
      await fixAt(location, _b, after: const Duration(seconds: 20));
      expect(_queue.submitted, hasLength(1));

      await container.read(truckTrackingProvider.notifier).stop();
      expect(_queue.submitted, hasLength(2));
      expect(_queue.submitted.last.payload['@shipmentId'], 'SHP-1');
    });

    test('pasar a segundo plano encola el lote pendiente', () async {
      final (container, location) = await started();
      await fixAt(location, _a);
      await fixAt(location, _b, after: const Duration(seconds: 20));
      expect(_queue.submitted, hasLength(1));

      await _toBackground();
      expect(_queue.submitted, hasLength(2));
      expect(container.read(truckTrackingProvider.notifier).pendingBatch, 0);
    });

    test('cambiar de parada envía lo juntado con el envío anterior', () async {
      final (container, location) = await started();
      final notifier = container.read(truckTrackingProvider.notifier);
      await fixAt(location, _a);
      await fixAt(location, _b, after: const Duration(seconds: 20));

      await notifier.start(shipmentId: 'SHP-2');
      await pumpEventQueue();
      expect(_queue.submitted, hasLength(2));
      expect(_queue.submitted.last.payload['@shipmentId'], 'SHP-1');
    });
  });
}
