import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_token_response.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/auth_headers.dart';
import 'package:logistics_app/core/network/dio_client.dart';

import 'test_fakes.dart';

// Refresh proactivo del token: el chofer no se puede quedar sin sesión en
// medio de una entrega. Se renueva [refreshMargin] antes del vencimiento, al
// volver la app a primer plano, y nunca dos veces en paralelo. Si falla, la
// sesión NO se cierra (eso lo decide el 401).

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSecureStorage storage;
  late FakeAuthClient authClient;
  late ProviderContainer container;

  setUp(() {
    storage = FakeSecureStorage();
    authClient = FakeAuthClient();
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        logisticsApiProvider.overrideWithValue(FakeLogisticsApi(authClient)),
      ],
    );
    // Como en producción (`routerProvider`): alguien lo escucha desde el
    // arranque, así que reacciona a los cambios de sesión.
    container.listen(tokenRefreshProvider, (_, _) {});
    addTearDown(container.dispose);
  });

  SessionNotifier session() => container.read(sessionProvider.notifier);
  TokenRefreshNotifier refresher() =>
      container.read(tokenRefreshProvider.notifier);
  DateTime? scheduled() => container.read(tokenRefreshProvider);

  /// Deja correr los microtasks (rebuild del notifier, timers de duración 0).
  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  group('dueAt', () {
    final now = DateTime.utc(2026, 11, 12, 8);

    test('con vencimiento: 10 min antes', () {
      expect(
        TokenRefreshNotifier.dueAt(
          expiresAt: now.add(const Duration(hours: 1)),
          issuedAt: now,
          now: now,
        ),
        now.add(const Duration(minutes: 50)),
      );
    });

    test('vencimiento dentro del margen (o pasado): ahora', () {
      expect(
        TokenRefreshNotifier.dueAt(
          expiresAt: now.add(const Duration(minutes: 3)),
          issuedAt: now,
          now: now,
        ),
        now,
      );
      expect(
        TokenRefreshNotifier.dueAt(
          expiresAt: now.subtract(const Duration(days: 1)),
          issuedAt: now,
          now: now,
        ),
        now,
      );
    });

    test('sin vencimiento: por antigüedad del token', () {
      expect(
        TokenRefreshNotifier.dueAt(expiresAt: null, issuedAt: now, now: now),
        now.add(TokenRefreshNotifier.unknownExpiryMaxAge),
      );
      // Token viejo (copia de sesión de ayer): ya toca.
      expect(
        TokenRefreshNotifier.dueAt(
          expiresAt: null,
          issuedAt: now.subtract(const Duration(days: 2)),
          now: now,
        ),
        now,
      );
      // Sin ninguna fecha: se cuenta desde ahora (no se renueva de entrada).
      expect(
        TokenRefreshNotifier.dueAt(expiresAt: null, issuedAt: null, now: now),
        now.add(TokenRefreshNotifier.unknownExpiryMaxAge),
      );
    });
  });

  group('programación', () {
    test('sin sesión no programa nada', () {
      expect(scheduled(), isNull);
      expect(tokenRefreshHasTimer(refresher()), isFalse);
    });

    test('sesión dev (token null) no programa nada', () async {
      session().devSignIn(UserRole.driver);
      await settle();
      expect(scheduled(), isNull);
      expect(authClient.refreshCalls, 0);
    });

    test('con vencimiento lejano programa y no toca la red', () async {
      final expires = DateTime.now().add(const Duration(hours: 3));
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: expires,
      );
      await settle();

      expect(tokenRefreshHasTimer(refresher()), isTrue);
      final esperado = expires.subtract(TokenRefreshNotifier.refreshMargin);
      final desvio = scheduled()!.difference(esperado).inSeconds;
      expect(desvio.abs(), lessThan(2));
      expect(authClient.refreshCalls, 0);
    });

    test('sin expires_at cae a la política por antigüedad', () async {
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
      );
      await settle();

      final due = scheduled()!;
      expect(
        due.difference(DateTime.now()).inMinutes,
        closeTo(TokenRefreshNotifier.unknownExpiryMaxAge.inMinutes, 2),
      );
      expect(authClient.refreshCalls, 0);
    });
  });

  group('renovación', () {
    test('vencimiento dentro del margen: renueva solo y en silencio', () async {
      authClient.refreshResponse = AppTokenResponse(
        token: 'flamante',
        tokenType: 'Bearer',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
      );
      await session().signIn(
        token: 'viejo',
        userName: 'ana',
        role: UserRole.driver,
        // Faltan 4 min: menos que el margen de 10 → toca ya.
        expiresAt: DateTime.now().add(const Duration(minutes: 4)),
      );
      await settle();

      expect(authClient.refreshCalls, 1);
      expect(container.read(sessionProvider)!.token, 'flamante');
      expect(container.read(authHeadersProvider).bearerToken, 'flamante');
      // El vencimiento nuevo quedó guardado y reprogramó el timer.
      expect(container.read(sessionProvider)!.tokenExpiresAt, isNotNull);
      expect(tokenRefreshHasTimer(refresher()), isTrue);
    });

    test('refreshIfDue (volver a primer plano) no renueva si falta', () async {
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: DateTime.now().add(const Duration(hours: 5)),
      );
      await settle();

      refresher().refreshIfDue();
      await settle();
      expect(authClient.refreshCalls, 0);
      expect(container.read(sessionProvider)!.token, 'tok');
    });

    test('refreshIfDue renueva cuando el token ya venció', () async {
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      // El timer de duración 0 ya corrió; igual el regreso a primer plano es
      // idempotente (el token nuevo ya no está vencido).
      await settle();
      final llamadas = authClient.refreshCalls;
      expect(llamadas, 1);

      refresher().refreshIfDue();
      await settle();
      expect(authClient.refreshCalls, llamadas);
    });

    test('no dispara dos renovaciones en paralelo', () async {
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: DateTime.now().add(const Duration(hours: 5)),
      );
      await settle();

      final a = refreshTokenQuietlyForTest(refresher());
      final b = refreshTokenQuietlyForTest(refresher());
      final c = session().refreshToken();
      await Future.wait([a, b, c]);

      expect(authClient.refreshCalls, 1);
    });

    test('si falla, NO cierra sesión y deja un reintento', () async {
      await session().signIn(
        token: 'viejo',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      );
      authClient.refreshError = dioResponseError(statusCode: 503);
      await settle();

      expect(authClient.refreshCalls, 1);
      // Sesión intacta: el token viejo sigue sirviendo hasta el 401.
      expect(container.read(sessionProvider)!.token, 'viejo');
      expect(container.read(authHeadersProvider).bearerToken, 'viejo');
      expect(container.read(sessionExpiredProvider), isNull);
      // Y hay un reintento más tarde (no se martilla al backend).
      expect(tokenRefreshHasTimer(refresher()), isTrue);
      final retryAt = scheduled()!;
      expect(
        retryAt.difference(DateTime.now()).inSeconds,
        greaterThan(TokenRefreshNotifier.failureRetryBase.inSeconds - 10),
      );
    });

    test('tras cerrar sesión no queda nada programado', () async {
      await session().signIn(
        token: 'tok',
        userName: 'ana',
        role: UserRole.driver,
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      await settle();
      expect(tokenRefreshHasTimer(refresher()), isTrue);

      await session().signOut();
      await settle();

      expect(scheduled(), isNull);
      expect(tokenRefreshHasTimer(refresher()), isFalse);
    });
  });
}
