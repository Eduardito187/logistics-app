import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/auth_headers.dart';
import 'package:logistics_app/core/network/dio_client.dart';

import '../auth/test_fakes.dart';

// _AuthInterceptor (vía dioProvider): inyección de cabeceras y manejo del 401
// global. Se reemplaza el transporte de Dio por un adaptador falso; nunca hay
// red real.

/// Adaptador de transporte falso: captura la request y devuelve una respuesta
/// canónica configurable (status + cuerpo JSON).
class _FakeAdapter implements HttpClientAdapter {
  int statusCode = 200;
  String body = '{}';
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeSecureStorage storage;
  late FakeAuthClient authClient;
  late ProviderContainer container;
  late Dio dio;
  late _FakeAdapter adapter;

  setUp(() {
    storage = FakeSecureStorage();
    authClient = FakeAuthClient();
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        logisticsApiProvider.overrideWithValue(FakeLogisticsApi(authClient)),
      ],
    );
    addTearDown(container.dispose);
    dio = container.read(dioProvider);
    adapter = _FakeAdapter();
    dio.httpClientAdapter = adapter;
  });

  Session? session() => container.read(sessionProvider);
  String? expiredMsg() => container.read(sessionExpiredProvider);

  Future<void> signedIn() => container
      .read(sessionProvider.notifier)
      .signIn(token: 'tok', userName: 'ana', role: UserRole.driver);

  group('onRequest: inyección de cabeceras', () {
    test(
      'agrega Authorization y X-Device-Id cuando hay token y deviceId',
      () async {
        container.read(authHeadersProvider.notifier)
          ..setToken('tok-abc')
          ..setDeviceId('dev-xyz');

        await dio.get<dynamic>('/app/shipments');

        final sent = adapter.lastRequest!.headers;
        expect(sent['Authorization'], 'Bearer tok-abc');
        expect(sent['X-Device-Id'], 'dev-xyz');
      },
    );

    test('sin token ni deviceId no agrega esas cabeceras', () async {
      await dio.get<dynamic>('/app/shipments');

      final sent = adapter.lastRequest!.headers;
      expect(sent.containsKey('Authorization'), isFalse);
      expect(sent.containsKey('X-Device-Id'), isFalse);
    });

    test('token vacío no genera Authorization', () async {
      container.read(authHeadersProvider.notifier).setToken('');
      await dio.get<dynamic>('/app/shipments');
      expect(
        adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('deviceId vacío no genera X-Device-Id', () async {
      container.read(authHeadersProvider.notifier).setDeviceId('');
      await dio.get<dynamic>('/app/shipments');
      expect(adapter.lastRequest!.headers.containsKey('X-Device-Id'), isFalse);
    });

    test('solo deviceId: agrega X-Device-Id, no Authorization', () async {
      container.read(authHeadersProvider.notifier).setDeviceId('dev-1');
      await dio.get<dynamic>('/app/shipments');
      final sent = adapter.lastRequest!.headers;
      expect(sent['X-Device-Id'], 'dev-1');
      expect(sent.containsKey('Authorization'), isFalse);
    });
  });

  group('onError: 401 en endpoint protegido', () {
    test('dispara el cierre de sesión global', () async {
      await signedIn();
      adapter.statusCode = 401;

      await expectLater(
        dio.get<dynamic>('/app/shipments'),
        throwsA(isA<DioException>()),
      );

      // El aviso se setea de inmediato; el cierre completa en segundo plano.
      expect(expiredMsg(), 'Tu sesión expiró, volvé a ingresar.');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(session(), isNull);
      expect(authClient.logoutCalls, 1);
    });

    test('sin sesión activa el 401 es no-op (no setea aviso)', () async {
      adapter.statusCode = 401;
      await expectLater(
        dio.get<dynamic>('/app/shipments'),
        throwsA(isA<DioException>()),
      );
      expect(expiredMsg(), isNull);
      expect(session(), isNull);
    });
  });

  group('onError: 401 en endpoints de autenticación NO desloguea', () {
    test('ruta con /login conserva la sesión', () async {
      await signedIn();
      adapter.statusCode = 401;

      await expectLater(
        dio.post<dynamic>('/app/auth/login'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(session(), isNotNull); // sigue adentro.
      expect(expiredMsg(), isNull);
      expect(authClient.logoutCalls, 0);
    });

    test('ruta con /token conserva la sesión', () async {
      await signedIn();
      adapter.statusCode = 401;

      await expectLater(
        dio.post<dynamic>('/app/access-tokens/abc/token'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(session(), isNotNull);
      expect(expiredMsg(), isNull);
    });
  });

  group(
    'onError: 403 no desloguea y se propaga como ApiException.isForbidden',
    () {
      test('conserva la sesión y mapea a ApiException sin permiso', () async {
        await signedIn();
        adapter
          ..statusCode = 403
          ..body = '{"title":"Sin permiso","code":"forbidden"}';

        Object? caught;
        try {
          await dio.get<dynamic>('/app/shipments');
        } on DioException catch (e) {
          caught = e;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(caught, isA<DioException>());
        // La sesión sigue viva: 403 no cierra.
        expect(session(), isNotNull);
        expect(expiredMsg(), isNull);
        // Como lo haría un data source: DioException -> ApiException.
        final api = ApiException.fromDio(caught! as DioException);
        expect(api.isForbidden, isTrue);
        expect(api.status, 403);
      });
    },
  );

  group('onError: otros códigos no desloguean', () {
    test('un 500 no cierra sesión', () async {
      await signedIn();
      adapter.statusCode = 500;

      await expectLater(
        dio.get<dynamic>('/app/shipments'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(session(), isNotNull);
      expect(expiredMsg(), isNull);
    });
  });
}
