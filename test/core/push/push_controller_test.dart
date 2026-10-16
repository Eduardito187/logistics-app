import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/core/push/push_service.dart';
import 'package:logistics_app/core/push/push_status.dart';

// PushController orquesta el registro push y publica PushStatus. Se sustituye
// PushService por un fake (captura los callbacks y controla distribuidores) y
// el endpoint provider por uno en memoria, para no tocar UnifiedPush ni el
// secure storage.

class _FakePushService extends PushService {
  void Function(String endpoint, String instance)? newEndpoint;
  void Function(String instance)? registrationFailed;
  void Function(String instance)? unregistered;
  void Function(Uint8List message, String instance)? message;
  void Function(String? payload)? tap;

  bool initializeThrows = false;
  String? saved;
  List<String> distributors = ['org.ntfy'];
  bool permissionGranted = true;

  int registerCalls = 0;
  int unregisterCalls = 0;
  int permissionCalls = 0;
  int availableCalls = 0;
  final List<String> savedDistributors = [];
  PushMessage decoded = const PushMessage(title: 'd', body: 'db');
  final List<PushMessage> shown = [];

  @override
  Future<void> initialize({
    required void Function(String endpoint, String instance) onNewEndpoint,
    required void Function(String instance) onRegistrationFailed,
    required void Function(String instance) onUnregistered,
    required void Function(Uint8List message, String instance) onMessage,
    required void Function(String? payload) onTap,
  }) async {
    if (initializeThrows) {
      throw StateError('no hay distribuidor');
    }
    newEndpoint = onNewEndpoint;
    registrationFailed = onRegistrationFailed;
    unregistered = onUnregistered;
    message = onMessage;
    tap = onTap;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    permissionCalls++;
    return permissionGranted;
  }

  @override
  Future<List<String>> availableDistributors() async {
    availableCalls++;
    return distributors;
  }

  @override
  Future<String?> savedDistributor() async => saved;

  @override
  Future<void> saveDistributor(String distributor) async {
    saved = distributor;
    savedDistributors.add(distributor);
  }

  @override
  Future<void> register() async {
    registerCalls++;
  }

  @override
  Future<void> unregister() async {
    unregisterCalls++;
  }

  @override
  PushMessage decodeMessage(Uint8List bytes) => decoded;

  @override
  Future<void> showMessage(PushMessage message) async {
    shown.add(message);
  }
}

class _FakeEndpoint extends PushEndpointNotifier {
  _FakeEndpoint([this._seed]);
  final String? _seed;

  @override
  String? build() => _seed;

  @override
  Future<void> save(String endpoint) async {
    state = endpoint;
  }

  @override
  Future<void> clear() async {
    state = null;
  }
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

ProviderContainer _container(_FakePushService service, {String? seedEndpoint}) {
  final container = ProviderContainer(
    overrides: [
      pushServiceProvider.overrideWithValue(service),
      pushEndpointProvider.overrideWith(() => _FakeEndpoint(seedEndpoint)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('bootstrap (build)', () {
    test('sin distribuidor guardado queda idle y no registra', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service);

      container.read(pushRegistrationProvider);
      await _flush();

      expect(
        container.read(pushRegistrationProvider).state,
        PushRegistrationState.idle,
      );
      expect(service.registerCalls, 0);
    });

    test(
      'con distribuidor y sin endpoint: registering y reintenta registro',
      () async {
        final service = _FakePushService()..saved = 'org.ntfy';
        final container = _container(service);

        container.read(pushRegistrationProvider);
        await _flush();

        final status = container.read(pushRegistrationProvider);
        expect(status.state, PushRegistrationState.registering);
        expect(status.distributor, 'org.ntfy');
        expect(service.registerCalls, 1);
      },
    );

    test('con distribuidor y endpoint guardado: registered', () async {
      final service = _FakePushService()..saved = 'org.ntfy';
      final container = _container(service, seedEndpoint: 'https://ntfy.sh/e');

      container.read(pushRegistrationProvider);
      await _flush();

      final status = container.read(pushRegistrationProvider);
      expect(status.state, PushRegistrationState.registered);
      expect(status.endpoint, 'https://ntfy.sh/e');
    });

    test(
      'un fallo en initialize no tumba la app: estado failed con mensaje',
      () async {
        final service = _FakePushService()..initializeThrows = true;
        final container = _container(service);

        container.read(pushRegistrationProvider);
        await _flush();

        final status = container.read(pushRegistrationProvider);
        expect(status.state, PushRegistrationState.failed);
        expect(status.message, contains('No se pudo iniciar el push'));
      },
    );
  });

  group('register()', () {
    test('pide permiso, toma el primer distribuidor y registra', () async {
      final service = _FakePushService()
        ..saved = null
        ..distributors = ['org.ntfy', 'org.otro'];
      final container = _container(service);
      final notifier = container.read(pushRegistrationProvider.notifier);
      await _flush();

      await notifier.register();

      expect(service.permissionCalls, greaterThanOrEqualTo(1));
      expect(service.savedDistributors, contains('org.ntfy'));
      expect(service.registerCalls, greaterThanOrEqualTo(1));
      final status = container.read(pushRegistrationProvider);
      expect(status.state, PushRegistrationState.registering);
      expect(status.distributor, 'org.ntfy');
    });

    test(
      'sin distribuidores instalados: unavailable con instrucción',
      () async {
        final service = _FakePushService()
          ..saved = null
          ..distributors = [];
        final container = _container(service);
        final notifier = container.read(pushRegistrationProvider.notifier);
        await _flush();

        await notifier.register();

        final status = container.read(pushRegistrationProvider);
        expect(status.state, PushRegistrationState.unavailable);
        expect(status.message, contains('ntfy'));
      },
    );

    test('si ya hay distribuidor guardado no busca la lista', () async {
      final service = _FakePushService()..saved = 'org.ntfy';
      final container = _container(service);
      final notifier = container.read(pushRegistrationProvider.notifier);
      await _flush();
      service.availableCalls = 0; // ignorar lo del bootstrap

      await notifier.register();

      expect(service.availableCalls, 0);
      expect(container.read(pushRegistrationProvider).distributor, 'org.ntfy');
    });
  });

  group('unregister()', () {
    test('da de baja, limpia el endpoint y vuelve a idle', () async {
      final service = _FakePushService()..saved = 'org.ntfy';
      final container = _container(service, seedEndpoint: 'https://ntfy.sh/e');
      final notifier = container.read(pushRegistrationProvider.notifier);
      await _flush();

      await notifier.unregister();

      expect(service.unregisterCalls, 1);
      expect(container.read(pushEndpointProvider), isNull);
      expect(
        container.read(pushRegistrationProvider).state,
        PushRegistrationState.idle,
      );
    });
  });

  group('callbacks de UnifiedPush', () {
    test('onNewEndpoint guarda el endpoint y pasa a registered', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service);
      container.read(pushRegistrationProvider);
      await _flush();

      service.newEndpoint!('https://ntfy.sh/nuevo', 'instancia');
      await _flush();

      expect(container.read(pushEndpointProvider), 'https://ntfy.sh/nuevo');
      final status = container.read(pushRegistrationProvider);
      expect(status.state, PushRegistrationState.registered);
      expect(status.endpoint, 'https://ntfy.sh/nuevo');
    });

    test('onRegistrationFailed pasa a failed con mensaje', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service);
      container.read(pushRegistrationProvider);
      await _flush();

      service.registrationFailed!('instancia');
      await _flush();

      final status = container.read(pushRegistrationProvider);
      expect(status.state, PushRegistrationState.failed);
      expect(status.message, 'El distribuidor rechazó el registro.');
    });

    test('onUnregistered limpia endpoint y pasa a unregistered', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service, seedEndpoint: 'https://ntfy.sh/e');
      container.read(pushRegistrationProvider);
      await _flush();

      service.unregistered!('instancia');
      await _flush();

      expect(container.read(pushEndpointProvider), isNull);
      expect(
        container.read(pushRegistrationProvider).state,
        PushRegistrationState.unregistered,
      );
    });

    test('onMessage decodifica y muestra la notificación local', () async {
      final service = _FakePushService()..saved = null;
      service.decoded = const PushMessage(title: 'Ruta', body: 'Sal ya');
      final container = _container(service);
      container.read(pushRegistrationProvider);
      await _flush();

      service.message!(Uint8List.fromList([1, 2, 3]), 'instancia');
      await _flush();

      expect(service.shown, hasLength(1));
      expect(service.shown.single.title, 'Ruta');
    });

    test('onTap emite el payload en el stream taps', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service);
      final notifier = container.read(pushRegistrationProvider.notifier);
      await _flush();

      final emitted = <String>[];
      final sub = notifier.taps.listen(emitted.add);

      service.tap!('SHP-1');
      service.tap!(null); // payload null -> cadena vacía
      await _flush();

      expect(emitted, ['SHP-1', '']);
      await sub.cancel();
    });

    test('pushTapProvider refleja el último tap emitido', () async {
      final service = _FakePushService()..saved = null;
      final container = _container(service);
      // Suscribir el StreamProvider antes de emitir (también construye el
      // controller, que es quien captura el callback onTap).
      final sub = container.listen(pushTapProvider, (_, next) {});
      await _flush();

      service.tap!('N-7');
      await _flush();

      expect(container.read(pushTapProvider).value, 'N-7');
      sub.close();
    });
  });
}
