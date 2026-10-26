import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_service.dart';
import 'package:logistics_app/core/push/push_status.dart';

// PushController (FCM) con un PushService falso: arranque con/sin credenciales,
// re-registro con permiso previo, activación por el usuario, permiso denegado,
// rotación/baja del identificador y taps de notificación.

class _FakePushService implements PushService {
  bool configured = true;
  bool permissionGranted = false;
  bool grantOnRequest = true;
  Object? initError;
  int registerCalls = 0;
  int unregisterCalls = 0;

  void Function(String token)? onToken;
  void Function(String? payload)? onTap;
  void Function()? onUnregistered;

  @override
  Future<bool> initialize({
    required void Function(String token) onToken,
    required void Function(String? payload) onTap,
    void Function()? onUnregistered,
  }) async {
    if (initError != null) throw initError!;
    this.onToken = onToken;
    this.onTap = onTap;
    this.onUnregistered = onUnregistered;
    return configured;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async {
    permissionGranted = grantOnRequest;
    return grantOnRequest;
  }

  @override
  Future<void> registerDevice() async {
    registerCalls++;
    onToken?.call('fid-$registerCalls');
  }

  @override
  Future<void> unregister() async => unregisterCalls++;

  final List<String> topicCalls = [];

  @override
  Future<void> subscribeToTopic(String topic) async =>
      topicCalls.add('+$topic');

  @override
  Future<void> unsubscribeFromTopic(String topic) async =>
      topicCalls.add('-$topic');

  int cancelCalls = 0;

  @override
  Future<void> cancelSubscriptions() async => cancelCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Cola offline falsa: registra lo encolado.
class _FakeQueue implements OfflineQueue {
  final List<({String kind, Map<String, Object?> payload})> submitted = [];

  @override
  Future<SubmitOutcome> submit({
    required String kind,
    required Map<String, Object?> payload,
    required String label,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async {
    submitted.add((kind: kind, payload: payload));
    return SubmitOutcome.queued;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakePushService service;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    service = _FakePushService();
  });

  late _FakeQueue queue;

  ProviderContainer make({bool configured = true}) {
    queue = _FakeQueue();
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(service),
        pushConfiguredProvider.overrideWithValue(configured),
        offlineQueueProvider.overrideWithValue(queue),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'sin credenciales de Firebase queda "no disponible" y no inicia',
    () async {
      final container = make(configured: false);

      final status = container.read(pushRegistrationProvider);
      await pumpEventQueue();

      expect(status.state, PushRegistrationState.unavailable);
      expect(service.onToken, isNull); // nunca inicializó
    },
  );

  test('register sin credenciales tampoco intenta nada', () async {
    final container = make(configured: false);
    container.read(pushRegistrationProvider);

    await container.read(pushRegistrationProvider.notifier).register();

    expect(
      container.read(pushRegistrationProvider).state,
      PushRegistrationState.unavailable,
    );
    expect(service.registerCalls, 0);
  });

  test('arranque con permiso previo: se re-registra y guarda el id', () async {
    service.permissionGranted = true;
    final container = make();

    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    final status = container.read(pushRegistrationProvider);
    expect(status.isRegistered, isTrue);
    expect(status.token, 'fid-1');
    expect(container.read(pushTokenProvider), 'fid-1');
  });

  test(
    'arranque sin permiso: queda inactivo hasta que el usuario active',
    () async {
      final container = make();

      container.read(pushRegistrationProvider);
      await pumpEventQueue();

      expect(
        container.read(pushRegistrationProvider).state,
        PushRegistrationState.idle,
      );
      expect(service.registerCalls, 0);
    },
  );

  test('register: pide permiso, registra y queda activo', () async {
    final container = make();
    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    await container.read(pushRegistrationProvider.notifier).register();

    final status = container.read(pushRegistrationProvider);
    expect(status.isRegistered, isTrue);
    expect(status.message, isNull);
    expect(container.read(pushTokenProvider), 'fid-1');
  });

  test('register con permiso denegado: error claro y sin registrar', () async {
    service.grantOnRequest = false;
    final container = make();
    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    await container.read(pushRegistrationProvider.notifier).register();

    final status = container.read(pushRegistrationProvider);
    expect(status.state, PushRegistrationState.failed);
    expect(status.message, contains('Permiso de notificaciones denegado'));
    expect(service.registerCalls, 0);
  });

  test('un identificador rotado por FCM reemplaza al anterior', () async {
    service.permissionGranted = true;
    final container = make();
    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    service.onToken!('fid-rotado');
    await pumpEventQueue();

    expect(container.read(pushRegistrationProvider).token, 'fid-rotado');
    expect(container.read(pushTokenProvider), 'fid-rotado');
  });

  test('unregister da de baja en FCM y olvida el identificador', () async {
    service.permissionGranted = true;
    final container = make();
    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    await container.read(pushRegistrationProvider.notifier).unregister();

    expect(service.unregisterCalls, 1);
    expect(
      container.read(pushRegistrationProvider).state,
      PushRegistrationState.idle,
    );
    expect(container.read(pushTokenProvider), isNull);
  });

  test('baja informada por FCM (onUnregistered) también lo olvida', () async {
    service.permissionGranted = true;
    final container = make();
    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    service.onUnregistered!();
    await pumpEventQueue();

    expect(container.read(pushRegistrationProvider).isRegistered, isFalse);
    expect(container.read(pushTokenProvider), isNull);
  });

  test('un error de plataforma al iniciar no tumba la app', () async {
    service.initError = StateError('sin Google Play Services');
    final container = make();

    container.read(pushRegistrationProvider);
    await pumpEventQueue();

    final status = container.read(pushRegistrationProvider);
    expect(status.state, PushRegistrationState.failed);
    expect(status.message, contains('No se pudo iniciar el push'));
  });

  test('los taps se publican en pushTapProvider (payload o vacío)', () async {
    final container = make();
    final taps = <String>[];
    container.read(pushRegistrationProvider);
    await pumpEventQueue();
    final sub = container
        .read(pushRegistrationProvider.notifier)
        .taps
        .listen(taps.add);
    addTearDown(sub.cancel);

    service.onTap!('N-1');
    service.onTap!(null);
    await pumpEventQueue();

    expect(taps, ['N-1', '']);
  });

  group('sincronización con el backend', () {
    test(
      'sin sesión el token NO se manda (viaja en el próximo login)',
      () async {
        service.permissionGranted = true;
        final container = make();
        container.read(pushRegistrationProvider);
        await pumpEventQueue();

        expect(container.read(pushTokenProvider), 'fid-1');
        expect(queue.submitted, isEmpty);
      },
    );

    test('con sesión, un token rotado se encola como PUT push-token', () async {
      service.permissionGranted = true;
      final container = make();
      await container
          .read(sessionProvider.notifier)
          .signIn(token: 't', userName: 'U', role: UserRole.driver);
      container.read(pushRegistrationProvider);
      await pumpEventQueue();

      service.onToken!('fid-rotado');
      await pumpEventQueue();

      expect(queue.submitted.last.kind, 'updateDevicePushToken');
      expect(queue.submitted.last.payload, {'push_token': 'fid-rotado'});
    });

    test('el mismo token no se reenvía', () async {
      service.permissionGranted = true;
      final container = make();
      await container
          .read(sessionProvider.notifier)
          .signIn(token: 't', userName: 'U', role: UserRole.driver);
      container.read(pushRegistrationProvider);
      await pumpEventQueue();
      final before = queue.submitted.length;

      service.onToken!('fid-1');
      await pumpEventQueue();

      expect(queue.submitted.length, before);
    });

    test('unregister con sesión avisa push_token: null', () async {
      service.permissionGranted = true;
      final container = make();
      await container
          .read(sessionProvider.notifier)
          .signIn(token: 't', userName: 'U', role: UserRole.driver);
      container.read(pushRegistrationProvider);
      await pumpEventQueue();

      await container.read(pushRegistrationProvider.notifier).unregister();

      expect(queue.submitted.last.payload, {'push_token': null});
    });
  });

  group('topics por rol y tienda', () {
    test(
      'se suscribe a role_<rol> al iniciar sesión y se baja al salir',
      () async {
        final container = make();
        container.read(pushRegistrationProvider);
        await pumpEventQueue();

        container.read(sessionProvider.notifier).devSignIn(UserRole.driver);
        await pumpEventQueue();
        expect(service.topicCalls, ['+role_chofer']);

        await container.read(sessionProvider.notifier).signOut();
        await pumpEventQueue();
        expect(service.topicCalls, ['+role_chofer', '-role_chofer']);
      },
    );
  });

  test('al destruir el provider suelta los listeners de FCM', () async {
    final container = ProviderContainer(
      overrides: [
        pushServiceProvider.overrideWithValue(service),
        pushConfiguredProvider.overrideWithValue(true),
        offlineQueueProvider.overrideWithValue(_FakeQueue()),
      ],
    );
    container.read(pushRegistrationProvider);
    await Future<void>.delayed(Duration.zero);
    container.dispose();
    expect(service.cancelCalls, 1);
  });
}
