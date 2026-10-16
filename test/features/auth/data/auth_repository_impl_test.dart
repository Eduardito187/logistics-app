import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/auth_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
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
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';

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
}

/// Endpoint push: nace en null y no lee el almacén.
class _FakePushEndpoint extends PushEndpointNotifier {
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
    this.loginError,
    this.meResponse,
    this.meError,
  });

  final AppLoginResponse? loginResponse;
  final Object? loginError;
  final AppMeResponse? meResponse;
  final Object? meError;

  @override
  Future<AppLoginResponse> login(AppLoginRequest request) async {
    if (loginError != null) throw loginError!;
    return loginResponse!;
  }

  @override
  Future<AppMeResponse> me() async {
    if (meError != null) throw meError!;
    return meResponse!;
  }
}

AppLoginResponse _loginWithRoles(List<String> roles) => AppLoginResponse(
  token: 'tok-123',
  tokenType: 'Bearer',
  expiresAt: null,
  user: AppUserProfile(
    id: 1,
    name: 'Juan Pérez',
    email: 'juan@x.com',
    roles: roles,
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
      pushEndpointProvider.overrideWith(_FakePushEndpoint.new),
      labelKeysProvider.overrideWith(_FakeLabelKeys.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// --- Falsos para el data source (Dio) --------------------------------------

class _FakeAuthClient implements AuthClient {
  _FakeAuthClient({this.loginThrows = false});
  final bool loginThrows;

  @override
  Future<AppLoginResponse> appLogin({required AppLoginRequest body}) async {
    if (loginThrows) {
      throw DioException(
        requestOptions: RequestOptions(path: '/app/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/app/auth/login'),
          statusCode: 401,
          data: const {'title': 'Sesión no válida', 'detail': 'Credenciales.'},
        ),
      );
    }
    return _loginWithRoles(['chofer']);
  }

  @override
  Future<AppMeResponse> appMe() async => const AppMeResponse(
    user: AppUserProfile(
      id: 1,
      name: 'Juan',
      email: 'j@x.com',
      roles: ['chofer'],
    ),
    device: null,
    abilities: [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeApi extends LogisticsApi {
  _FakeApi(this._authClient) : super(Dio());
  final AuthClient _authClient;
  @override
  AuthClient get auth => _authClient;
}

void main() {
  group('AuthRepositoryImpl (vía SignIn)', () {
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
                .having((e) => e.detail, 'detail', contains('rol')),
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
    test('login ok: devuelve el AppLoginResponse del cliente', () async {
      final container = ProviderContainer(
        overrides: [
          logisticsApiProvider.overrideWithValue(_FakeApi(_FakeAuthClient())),
        ],
      );
      addTearDown(container.dispose);

      final ds = container.read(authRemoteDataSourceProvider);
      final response = await ds.login(
        const AppLoginRequest(
          email: 'a@x.com',
          password: 'b',
          device: Device(fingerprint: 'dev-1'),
        ),
      );
      expect(response.token, 'tok-123');
    });

    test('DioException se convierte en ApiException', () async {
      final container = ProviderContainer(
        overrides: [
          logisticsApiProvider.overrideWithValue(
            _FakeApi(_FakeAuthClient(loginThrows: true)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ds = container.read(authRemoteDataSourceProvider);
      await expectLater(
        ds.login(
          const AppLoginRequest(
            email: 'a@x.com',
            password: 'b',
            device: Device(fingerprint: 'dev-1'),
          ),
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });
  });
}
