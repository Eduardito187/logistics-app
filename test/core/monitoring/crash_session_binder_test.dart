import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_status.dart';
import 'package:logistics_app/core/api/models/node_type.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/monitoring/crash_reporter.dart';
import 'package:logistics_app/core/monitoring/crash_session_binder.dart';
import 'package:logistics_app/core/network/auth_headers.dart';

import 'fake_crash_reporter.dart';

/// Sesión controlable sin red ni almacén seguro.
class _TestSessionNotifier extends SessionNotifier {
  @override
  Session? build() => null;

  void set(Session? session) => state = session;
}

const _store = Node(
  id: 'node-42',
  code: 'T42',
  name: 'Tienda Centro',
  type: NodeType.store,
  lat: 0,
  lng: 0,
  status: NodeStatus.active,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeCrashReporter reporter;
  late ProviderContainer container;

  setUp(() {
    reporter = FakeCrashReporter();
    container = ProviderContainer(
      overrides: [
        crashReporterProvider.overrideWithValue(reporter),
        sessionProvider.overrideWith(_TestSessionNotifier.new),
      ],
    );
    container.read(crashSessionBinderProvider);
  });

  tearDown(() => container.dispose());

  _TestSessionNotifier notifier() =>
      container.read(sessionProvider.notifier) as _TestSessionNotifier;

  test('id seudónimo: estable, sin el nombre de usuario', () async {
    final a = await pseudonymousUserId('juan.perez');
    final b = await pseudonymousUserId(' Juan.Perez ');
    expect(a, b);
    expect(a, startsWith('u_'));
    expect(a, hasLength(18));
    expect(a, isNot(contains('juan')));
    expect(await pseudonymousUserId('otro'), isNot(a));
  });

  test('al iniciar sesión setea usuario, rol y tienda (sin nombre)', () async {
    notifier().set(
      const Session(
        userName: 'maria.lopez',
        role: UserRole.store,
        storeNode: _store,
      ),
    );
    await _settle();
    await _settle();

    final user = reporter.users.whereType<CrashUserContext>().single;
    expect(user.userId, await pseudonymousUserId('maria.lopez'));
    expect(user.userId, isNot(contains('maria')));
    expect(user.role, 'tienda');
    expect(user.storeNodeId, 'node-42');
    expect(reporter.breadcrumbs, contains('session.sign_in'));
  });

  test('al cerrar sesión limpia el usuario', () async {
    notifier().set(const Session(userName: 'x', role: UserRole.driver));
    await _settle();
    await _settle();
    notifier().set(null);
    await _settle();

    expect(reporter.users.last, isNull);
    expect(reporter.breadcrumbs, contains('session.sign_out'));
  });

  test('cambios rápidos: el último estado gana', () async {
    notifier().set(const Session(userName: 'x', role: UserRole.driver));
    notifier().set(null);
    await _settle();
    await _settle();
    expect(reporter.users.whereType<CrashUserContext>(), isEmpty);
  });

  test('el device id queda como clave de contexto', () {
    container.read(authHeadersProvider.notifier).setDeviceId('dev-1');
    expect(reporter.keys[CrashKeys.deviceId], 'dev-1');
  });
}
