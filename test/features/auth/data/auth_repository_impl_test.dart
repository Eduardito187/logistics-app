import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/app_device_payload.dart';
import 'package:logistics_app/core/api/models/app_login_request.dart';
import 'package:logistics_app/core/api/models/device.dart';
import 'package:logistics_app/core/api/models/app_login_response.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/labels/label_keys_notifier.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/push/push_controller.dart';
import 'package:logistics_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:logistics_app/features/auth/domain/entities/login_result.dart';
import 'package:logistics_app/features/auth/domain/entities/two_factor_challenge.dart';
import 'package:logistics_app/features/auth/domain/entities/two_factor_enrollment.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';

import '../../store/store_fixtures.dart';

// Capa data de auth. Dos niveles:
//  1. AuthRepositoryImpl (vía SignIn): mapea rol, abre sesión, carga abilities
//     de /me con degradación segura, y convierte 401/422 en "credenciales".
//  2. AuthRemoteDataSource: convierte DioException en ApiException.
// Todo con falsos; nada de Dio ni almacenamiento real.

// --- Falsos de infraestructura compartidos ---------------------------------

/// TokenStore que no toca el almacén seguro real.
class _FakeTokenStore extends TokenStore {
  _FakeTokenStore() : super(const FlutterSecureStorage());
  @override
  Future<String> deviceId() async => 'device-1';
  @override
  Future<void> writeToken(String token) async {}
  @override
  Future<void> clearToken() async {}
  @override
  Future<String?> readToken() async => null;
  @override
  Future<void> writeSessionSnapshot(Map<String, Object?> snapshot) async {}
  @override
  Future<Map<String, Object?>?> readSessionSnapshot() async => null;
  @override
  Future<void> clearSessionSnapshot() async {}
}

/// Token push: nace en null y no lee el almacén.
class _FakePushToken extends PushTokenNotifier {
  @override
  String? build() => null;
}

/// Claves de etiquetas: sin arranque ni refresco contra la API.
class _FakeLabelKeys extends LabelKeysNotifier {
  @override
  Map<int, List<int>> build() => <int, List<int>>{};
  @override
  Future<void> refresh() async {}
}

/// Data source falso: respuestas configurables para login y me.
class _FakeAuthRemote implements AuthRemoteDataSource {
  _FakeAuthRemote({
    this.loginResponse,
    this.loginChallenge,
    this.loginError,
    this.meResponse,
    this.meError,
  });

  final AppLoginResponse? loginResponse;
  final TwoFactorChallenge? loginChallenge;
  final Object? loginError;
  final AppMeResponse? meResponse;
  final Object? meError;

  @override
  Future<LoginRaw> login(AppLoginRequest request) async {
    if (loginError != null) throw loginError!;
    return (success: loginResponse, challenge: loginChallenge);
  }

  @override
  Future<AppLoginResponse> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResponse!;
  }

  @override
  Future<AppMeResponse> me() async {
    if (meError != null) throw meError!;
    return meResponse!;
  }

  @override
  Future<TwoFactorEnrollment> enrollTwoFactor() => throw UnimplementedError();

  @override
  Future<void> confirmTwoFactor(String code) async {}

  @override
  Future<void> disableTwoFactor({String? code, String? password}) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {}
}

AppLoginResponse _loginWithRoles(List<String> roles, {Node? node}) =>
    AppLoginResponse(
      token: 'tok-123',
      tokenType: 'Bearer',
      expiresAt: null,
      user: AppUserProfile(
        id: 1,
        name: 'Juan Pérez',
        email: 'juan@x.com',
        roles: roles,
        node: node,
      ),
      device: const AppDevicePayload(
        uuid: 'dev-uuid',
        platform: 'android',
        name: 'App interna',
        lastSeenAt: null,
      ),
    );

ProviderContainer _container(_FakeAuthRemote remote) {
  final container = ProviderContainer(
    overrides: [
      authRemoteDataSourceProvider.overrideWithValue(remote),
      tokenStoreProvider.overrideWithValue(_FakeTokenStore()),
      pushTokenProvider.overrideWith(_FakePushToken.new),
      labelKeysProvider.overrideWith(_FakeLabelKeys.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// --- Falso de Dio para el data source (login usa Dio directo) ---------------

/// Adaptador HTTP falso: responde con un cuerpo y estado fijos, sin red. Sirve
/// para probar `AuthRemoteDataSource.login`, que ahora llama Dio directo (los
/// endpoints de 2FA/password no están en el cliente generado).
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _fakeDio({required int statusCode, required String body}) =>
    Dio(BaseOptions(validateStatus: (s) => s != null && s < 400))
      ..httpClientAdapter = _FakeDioAdapter(statusCode: statusCode, body: body);

void main() {
  group('AuthRepositoryImpl (vía SignIn)', () {
    test('login con 2FA: no abre sesión, devuelve el reto', () async {
      final remote = _FakeAuthRemote(
        loginChallenge: const TwoFactorChallenge(
          challengeId: 'ch-9',
          expiresInSeconds: 300,
        ),
      );
      final container = _container(remote);

      final result = await container
          .read(signInProvider)
          .call(email: 'a@x.com', password: 'b');

      expect(result, isA<LoginNeedsTwoFactor>());
      expect((result as LoginNeedsTwoFactor).challenge.challengeId, 'ch-9');
      expect(container.read(sessionProvider), isNull); // no abrió sesión
    });

    test('usuario tienda: la sesión guarda su tienda (login y /me)', () async {
      final tienda = storeNode(name: 'Tienda Norte', code: 'ST-09');
      final remote = _FakeAuthRemote(
        loginResponse: _loginWithRoles(['tienda'], node: tienda),
        meResponse: AppMeResponse(
          user: AppUserProfile(
            id: 1,
            name: 'Juan',
            email: 'j@x.com',
            roles: const ['tienda'],
            node: tienda,
          ),
          device: null,
          abilities: const [],
        ),
      );
      final container = _container(remote);

      await container
          .read(signInProvider)
          .call(email: 'juan@x.com', password: 'secret');

      final session = container.read(sessionProvider)!;
      expect(session.role, UserRole.store);
      expect(session.storeNode?.code, 'ST-09');
    });

    test('login ok con rol operativo: abre sesión y carga abilities', () async {
      final remote = _FakeAuthRemote(
        loginResponse: _loginWithRoles(['chofer']),
        meResponse: const AppMeResponse(
          user: AppUserProfile(
            id: 1,
            name: 'Juan',
            email: 'j@x.com',
            roles: ['chofer'],
          ),
          device: null,
          abilities: ['execution:write', 'labels:read'],
        ),
      );
      final container = _container(remote);

      await container
          .read(signInProvider)
          .call(email: 'juan@x.com', password: 'secret');

      final session = container.read(sessionProvider);
      expect(session, isNotNull);
      expect(session!.role, UserRole.driver);
      expect(session.userName, 'Juan Pérez');
      expect(session.token, 'tok-123');
      expect(
        session.abilities,
        containsAll(['execution:write', 'labels:read']),
      );
    });

    test(
      'si /me falla, la sesión queda abierta con abilities vacías',
      () async {
        final remote = _FakeAuthRemote(
          loginResponse: _loginWithRoles(['tienda']),
          meError: const ApiException(status: 403, title: 'Sin permiso'),
        );
        final container = _container(remote);

        await container
            .read(signInProvider)
            .call(email: 'a@x.com', password: 'b');

        final session = container.read(sessionProvider);
        expect(session, isNotNull);
        expect(session!.role, UserRole.store);
        expect(session.abilities, isEmpty); // degradación segura
      },
    );

    test(
      'usuario sin rol operativo (admin): lanza 403 y no abre sesión',
      () async {
        final remote = _FakeAuthRemote(
          loginResponse: _loginWithRoles(['admin']),
        );
        final container = _container(remote);

        await expectLater(
          container.read(signInProvider).call(email: 'a@x.com', password: 'b'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 403)
                .having((e) => e.detail, 'detail', contains('rol'))
                // Se muestra el motivo real, no el genérico "sin permiso".
                .having(
                  (e) => e.message,
                  'message',
                  contains('rol de terreno'),
                ),
          ),
        );
        expect(container.read(sessionProvider), isNull);
      },
    );

    test(
      '401 del backend: se convierte en "credenciales" y no abre sesión',
      () async {
        final remote = _FakeAuthRemote(
          loginError: const ApiException(
            status: 401,
            title: 'Sesión no válida',
          ),
        );
        final container = _container(remote);

        await expectLater(
          container
              .read(signInProvider)
              .call(email: 'a@x.com', password: 'mala'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', 401)
                .having(
                  (e) => e.detail,
                  'detail',
                  'Usuario o contraseña incorrectos.',
                ),
          ),
        );
        expect(container.read(sessionProvider), isNull);
      },
    );

    test('422 de validación: también se convierte en "credenciales"', () async {
      final remote = _FakeAuthRemote(
        loginError: const ApiException(status: 422, title: 'Datos inválidos'),
      );
      final container = _container(remote);

      await expectLater(
        container.read(signInProvider).call(email: 'a@x.com', password: ''),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having(
                (e) => e.detail,
                'detail',
                'Usuario o contraseña incorrectos.',
              ),
        ),
      );
    });

    test('un error 500 se propaga tal cual (no es "credenciales")', () async {
      final remote = _FakeAuthRemote(
        loginError: const ApiException(
          status: 500,
          title: 'Error del servidor',
        ),
      );
      final container = _container(remote);

      await expectLater(
        container.read(signInProvider).call(email: 'a@x.com', password: 'b'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('AuthRemoteDataSource', () {
    const request = AppLoginRequest(
      email: 'a@x.com',
      password: 'b',
      device: Device(fingerprint: 'dev-1'),
    );

    ProviderContainer dioContainer({
      required int statusCode,
      required String body,
    }) {
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(
            _fakeDio(statusCode: statusCode, body: body),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('login sin 2FA: devuelve success con el token', () async {
      final body = jsonEncode(_loginWithRoles(['chofer']).toJson());
      final container = dioContainer(statusCode: 200, body: body);

      final response = await container
          .read(authRemoteDataSourceProvider)
          .login(request);

      expect(response.challenge, isNull);
      expect(response.success, isNotNull);
      expect(response.success!.token, 'tok-123');
    });

    test('login con 2FA: devuelve el reto', () async {
      final body = jsonEncode({
        'two_factor_required': true,
        'challenge_id': 'ch-1',
        'expires_in': 300,
      });
      final container = dioContainer(statusCode: 200, body: body);

      final response = await container
          .read(authRemoteDataSourceProvider)
          .login(request);

      expect(response.success, isNull);
      expect(response.challenge, isNotNull);
      expect(response.challenge!.challengeId, 'ch-1');
    });

    test('DioException se convierte en ApiException', () async {
      final body = jsonEncode({
        'title': 'Sesión no válida',
        'detail': 'Credenciales.',
      });
      final container = dioContainer(statusCode: 401, body: body);

      await expectLater(
        container.read(authRemoteDataSourceProvider).login(request),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });
  });
}
