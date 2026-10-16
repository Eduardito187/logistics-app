import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_token_response.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/auth_headers.dart';
import 'package:logistics_app/core/network/dio_client.dart';

import 'test_fakes.dart';

// SessionNotifier con dependencias falsas: almacén seguro en memoria y API
// generada falsa (sin Dio real). Cubre signIn, setAbilities, devSignIn,
// refreshToken, signOut y handleUnauthorized (incl. idempotencia).

void main() {
  late FakeSecureStorage storage;
  late FakeAuthClient authClient;
  late ProviderContainer container;

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        logisticsApiProvider.overrideWithValue(FakeLogisticsApi(authClient)),
      ],
    );
  }

  setUp(() {
    storage = FakeSecureStorage();
    authClient = FakeAuthClient();
    container = makeContainer();
    addTearDown(container.dispose);
  });

  SessionNotifier notifier() => container.read(sessionProvider.notifier);
  Session? session() => container.read(sessionProvider);
  AuthHeaders headers() => container.read(authHeadersProvider);

  group('build inicial', () {
    test('la sesión arranca en null', () {
      expect(session(), isNull);
    });
  });

  group('signIn', () {
    test('guarda token, lo pone en cabeceras y arma la sesión', () async {
      await notifier().signIn(
        token: 'tok-1',
        userName: 'ana',
        role: UserRole.supervisor,
        abilities: ['dashboard.read'],
      );

      final s = session()!;
      expect(s.userName, 'ana');
      expect(s.role, UserRole.supervisor);
      expect(s.token, 'tok-1');
      expect(s.abilities, ['dashboard.read']);
      // Persistido y en cabeceras.
      expect(await container.read(tokenStoreProvider).readToken(), 'tok-1');
      expect(headers().bearerToken, 'tok-1');
    });

    test('abilities por defecto es lista vacía', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'x',
        role: UserRole.driver,
      );
      expect(session()!.abilities, isEmpty);
    });

    test(
      'con token vacío: la sesión lo guarda pero la cabecera queda vacía',
      () async {
        await notifier().signIn(
          token: '',
          userName: 'x',
          role: UserRole.driver,
        );
        expect(session()!.token, '');
        // setToken('') -> bearerToken '' (no null): el interceptor lo trata como
        // ausente, pero el modelo de cabeceras guarda la cadena vacía.
        expect(headers().bearerToken, '');
      },
    );
  });

  group('setAbilities', () {
    test('sin sesión activa no hace nada', () {
      notifier().setAbilities(['a', 'b']);
      expect(session(), isNull);
    });

    test('actualiza abilities conservando el resto de la sesión', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.store,
        abilities: ['vieja'],
      );
      notifier().setAbilities(['reception.read', 'reception.write']);

      final s = session()!;
      expect(s.abilities, ['reception.read', 'reception.write']);
      expect(s.userName, 'ana');
      expect(s.role, UserRole.store);
      expect(s.token, 'tok');
    });

    test('acepta lista vacía (degradación segura)', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.store,
        abilities: ['algo'],
      );
      notifier().setAbilities(const []);
      expect(session()!.abilities, isEmpty);
    });
  });

  group('devSignIn', () {
    test('entra por rol sin token ni abilities', () {
      notifier().devSignIn(UserRole.picker);
      final s = session()!;
      expect(s.userName, 'dev.picker');
      expect(s.role, UserRole.picker);
      expect(s.token, isNull);
      expect(s.abilities, isEmpty);
      // No toca cabeceras ni almacén.
      expect(headers().bearerToken, isNull);
    });
  });

  group('refreshToken', () {
    test('sin sesión lanza ApiException 401 "Sin sesión"', () async {
      await expectLater(
        notifier().refreshToken(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.title, 'title', 'Sin sesión'),
        ),
      );
    });

    test('con sesión dev (token null) lanza ApiException 401', () async {
      notifier().devSignIn(UserRole.driver);
      await expectLater(
        notifier().refreshToken(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
      expect(authClient.refreshCalls, 0); // nunca llega a la red.
    });

    test('éxito: rota el token en sesión, almacén y cabeceras', () async {
      await notifier().signIn(
        token: 'viejo',
        userName: 'ana',
        role: UserRole.driver,
        abilities: ['routes.read'],
      );
      authClient.refreshResponse = const AppTokenResponse(
        token: 'flamante',
        tokenType: 'Bearer',
        expiresAt: null,
      );

      await notifier().refreshToken();

      final s = session()!;
      expect(s.token, 'flamante');
      expect(s.userName, 'ana'); // se conserva el resto.
      expect(s.abilities, ['routes.read']);
      expect(await container.read(tokenStoreProvider).readToken(), 'flamante');
      expect(headers().bearerToken, 'flamante');
      expect(authClient.refreshCalls, 1);
    });

    test(
      'falla la renovación: convierte DioException en ApiException',
      () async {
        await notifier().signIn(
          token: 'viejo',
          userName: 'ana',
          role: UserRole.driver,
        );
        authClient.refreshError = dioResponseError(
          statusCode: 409,
          body: {'code': 'device_revoked', 'detail': 'Dispositivo revocado.'},
        );

        await expectLater(
          notifier().refreshToken(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 409)
                .having((e) => e.detail, 'detail', 'Dispositivo revocado.'),
          ),
        );
        // El token viejo sigue vigente: la renovación fallida no lo pisa.
        expect(session()!.token, 'viejo');
        expect(headers().bearerToken, 'viejo');
      },
    );
  });

  group('signOut', () {
    test('con token real: revoca en servidor y limpia todo', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );
      await notifier().signOut();

      expect(session(), isNull);
      expect(headers().bearerToken, isNull);
      expect(await container.read(tokenStoreProvider).readToken(), isNull);
      expect(authClient.logoutCalls, 1);
    });

    test(
      'sesión dev (token null): no llama appLogout pero limpia local',
      () async {
        notifier().devSignIn(UserRole.driver);
        await notifier().signOut();

        expect(session(), isNull);
        expect(authClient.logoutCalls, 0);
      },
    );

    test('si appLogout falla (sin red) igual cierra sesión local', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );
      authClient.logoutError = Exception('sin red');

      await notifier().signOut();

      expect(session(), isNull);
      expect(headers().bearerToken, isNull);
    });

    test('si clearToken del almacén falla, el cierre no se traba', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );
      storage.throwOnDelete = true; // delete (clearToken) lanza.

      await notifier().signOut();

      // El estado en memoria ya se limpió antes de tocar el almacén.
      expect(session(), isNull);
      expect(headers().bearerToken, isNull);
    });
  });

  group('handleUnauthorized', () {
    test('sin sesión no hace nada (no setea aviso)', () {
      notifier().handleUnauthorized();
      expect(container.read(sessionExpiredProvider), isNull);
      expect(session(), isNull);
    });

    test('con sesión: setea aviso y dispara el cierre', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );

      notifier().handleUnauthorized();

      // El aviso se setea de forma síncrona.
      expect(
        container.read(sessionExpiredProvider),
        'Tu sesión expiró, volvé a ingresar.',
      );
      // signOut corre en segundo plano (unawaited): dejamos que complete.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(session(), isNull);
    });

    test(
      'idempotencia: múltiples 401 seguidos no reinician cierre ni avisan de más',
      () async {
        await notifier().signIn(
          token: 'tok',
          userName: 'ana',
          role: UserRole.driver,
        );

        // Llegan tres 401 "en paralelo" antes de que el cierre termine.
        notifier()
          ..handleUnauthorized()
          ..handleUnauthorized()
          ..handleUnauthorized();
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(session(), isNull);
        // FALENCIA DETECTADA: el guard `if (state == null)` de
        // handleUnauthorized no protege contra 401 concurrentes. signOut() hace
        // `await appLogout()` ANTES de poner state = null, así que los 401 que
        // llegan mientras el logout está en vuelo ven state != null y vuelven a
        // entrar: se llama appLogout varias veces (revocaciones redundantes) y
        // el aviso se vuelve a setear. El comportamiento CORRECTO (prometido en
        // los comentarios de session_notifier.dart:120-122 y dio_client.dart:46)
        // es una sola revocación. Ver sección de falencias del reporte.
        expect(authClient.logoutCalls, 1);
      },
    );

    test('tras cerrar sesión, un 401 posterior es no-op', () async {
      await notifier().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );
      await notifier().signOut();
      container.read(sessionExpiredProvider.notifier).clear();

      notifier().handleUnauthorized();
      expect(container.read(sessionExpiredProvider), isNull);
    });
  });
}
