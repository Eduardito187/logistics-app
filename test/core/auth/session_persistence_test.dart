import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/auth_headers.dart';
import 'package:logistics_app/core/network/dio_client.dart';

import '../../features/store/store_fixtures.dart';
import 'test_fakes.dart';

// Sesión persistente (como WhatsApp): tras cerrar la app o reiniciar el
// teléfono, restore() la recupera del almacén seguro sin pasar por el login y
// sin red. Cada "reinicio" se simula con un ProviderContainer nuevo sobre el
// MISMO almacén.

void main() {
  late FakeSecureStorage storage;

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        logisticsApiProvider.overrideWithValue(
          FakeLogisticsApi(FakeAuthClient()),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => storage = FakeSecureStorage());

  test('tras iniciar sesión, reabrir la app la deja logueada', () async {
    final first = boot();
    await first
        .read(sessionProvider.notifier)
        .signIn(
          token: 'tok-1',
          userName: 'Ana Pérez',
          role: UserRole.store,
          abilities: const ['execution:write'],
        );

    // "Reinicio": contenedor nuevo, mismo almacén.
    final second = boot();
    final restored = await second.read(sessionProvider.notifier).restore();

    expect(restored, isTrue);
    final session = second.read(sessionProvider)!;
    expect(session.userName, 'Ana Pérez');
    expect(session.role, UserRole.store);
    expect(session.token, 'tok-1');
    expect(session.abilities, ['execution:write']);
    // El Bearer queda puesto para las requests.
    expect(second.read(authHeadersProvider).bearerToken, 'tok-1');
  });

  test('la tienda del usuario también sobrevive al reinicio', () async {
    final first = boot();
    await first
        .read(sessionProvider.notifier)
        .signIn(
          token: 't',
          userName: 'Ana',
          role: UserRole.store,
          storeNode: storeNode(name: 'Tienda Centro', code: 'ST-01'),
        );

    final second = boot();
    await second.read(sessionProvider.notifier).restore();

    final node = second.read(sessionProvider)!.storeNode;
    expect(node?.name, 'Tienda Centro');
    expect(node?.code, 'ST-01');
  });

  test('las abilities que llegan después también se recuerdan', () async {
    final first = boot();
    final notifier = first.read(sessionProvider.notifier);
    await notifier.signIn(token: 't', userName: 'U', role: UserRole.driver);
    notifier.setAbilities(const ['routes:read']);
    await pumpEventQueue();

    final second = boot();
    await second.read(sessionProvider.notifier).restore();

    expect(second.read(sessionProvider)!.abilities, ['routes:read']);
  });

  test('cerrar sesión borra la copia: al reabrir pide login', () async {
    final first = boot();
    await first
        .read(sessionProvider.notifier)
        .signIn(token: 't', userName: 'U', role: UserRole.driver);
    await first.read(sessionProvider.notifier).signOut();

    final second = boot();
    final restored = await second.read(sessionProvider.notifier).restore();

    expect(restored, isFalse);
    expect(second.read(sessionProvider), isNull);
  });

  test('sin nada guardado queda sin sesión', () async {
    final container = boot();
    expect(await container.read(sessionProvider.notifier).restore(), isFalse);
    expect(container.read(sessionProvider), isNull);
  });

  test('copia corrupta o rol desconocido: pide login sin reventar', () async {
    storage.data['app_bearer_token'] = 't';
    storage.data['app_session'] = '{no es json';
    var container = boot();
    expect(await container.read(sessionProvider.notifier).restore(), isFalse);

    storage.data['app_session'] = '{"userName":"U","role":"astronauta"}';
    container = boot();
    expect(await container.read(sessionProvider.notifier).restore(), isFalse);
    expect(container.read(sessionProvider), isNull);
  });

  test('el dev-login no se persiste (no tiene token)', () async {
    final first = boot();
    first.read(sessionProvider.notifier).devSignIn(UserRole.supervisor);

    final second = boot();
    expect(await second.read(sessionProvider.notifier).restore(), isFalse);
  });
}
