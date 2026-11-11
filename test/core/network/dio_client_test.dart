import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
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
  int calls = 0;

  /// Respuestas en orden (status, body) que se consumen antes de caer en
  /// [statusCode]/[body]: simula "primero 401, después 200".
  final List<(int, String)> queue = [];

  /// Se ejecuta MIENTRAS la request está "en vuelo" (antes de responder): sirve
  /// para simular que la sesión cambió entre el envío y la respuesta.
  Future<void> Function()? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    calls++;
    await onFetch?.call();
    final (status, payload) = queue.isNotEmpty
        ? queue.removeAt(0)
        : (statusCode, body);
    return ResponseBody.fromString(
      payload,
      status,
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

  /// Ventana de gracia tras login (en prod 35 s). Por defecto cero: los tests
  /// existentes de 401 cierran al instante; los de gracia la suben.
  var grace = Duration.zero;

  setUp(() {
    storage = FakeSecureStorage();
    authClient = FakeAuthClient();
    grace = Duration.zero;
    container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        logisticsApiProvider.overrideWithValue(FakeLogisticsApi(authClient)),
        deviceBindingGraceProvider.overrideWith((ref) => grace),
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

    test('401 session_superseded avisa "otro dispositivo" y cierra', () async {
      await signedIn();
      adapter.statusCode = 401;
      adapter.body = '{"code":"session_superseded"}';

      await expectLater(
        dio.get<dynamic>('/app/shipments'),
        throwsA(isA<DioException>()),
      );

      expect(expiredMsg(), 'Iniciaste sesión en otro dispositivo.');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(session(), isNull);
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

    test(
      'un 401 de request SIN token NO tumba una sesión creada mientras viajaba '
      '(bug "me logueé y expiró al instante")',
      () async {
        // El request sale SIN sesión (sin Authorization). Mientras viaja, entra
        // un login. Su 401 (tardío) no debe cerrar la sesión recién abierta.
        adapter.statusCode = 401;
        adapter.onFetch = () => container
            .read(sessionProvider.notifier)
            .signIn(token: 'tok-nuevo', userName: 'ana', role: UserRole.driver);

        await expectLater(
          dio.get<dynamic>('/app/shipments'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(expiredMsg(), isNull);
        expect(session(), isNotNull); // la sesión nueva sobrevive
      },
    );

    test(
      'un 401 de un token VIEJO (la sesión ya cambió) NO desloguea',
      () async {
        await signedIn(); // token 'tok' (viaja en el request)
        adapter.statusCode = 401;
        // Mientras el request con 'Bearer tok' viaja, entra una sesión nueva.
        adapter.onFetch = () async =>
            container.read(authHeadersProvider.notifier).setToken('tok-nuevo');

        await expectLater(
          dio.get<dynamic>('/app/shipments'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // El 401 era del token viejo: la sesión vigente (tok-nuevo) sigue viva.
        expect(expiredMsg(), isNull);
        expect(session(), isNotNull);
      },
    );
  });

  group('onError: login nuevo de OTRO usuario en el mismo teléfono '
      '(caché del backend desfasado)', () {
    const revoked = '{"code":"device_revoked"}';
    const superseded = '{"code":"session_superseded"}';

    test('401 device_revoked tras login reciente: reintenta y NO cierra '
        'la sesión (bug "dispositivo dado de baja")', () async {
      grace = const Duration(milliseconds: 150);
      await signedIn();
      adapter.queue
        ..add((401, revoked))
        ..add((200, '{"ok":true}'));

      final res = await dio.get<dynamic>('/app/shipments');

      expect(res.statusCode, 200);
      expect(adapter.calls, 2);
      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer tok');
      expect(expiredMsg(), isNull);
      expect(session(), isNotNull);
      expect(authClient.logoutCalls, 0);
    });

    test(
      '401 session_superseded tras login reciente también se reintenta',
      () async {
        grace = const Duration(milliseconds: 150);
        await signedIn();
        adapter.queue
          ..add((401, superseded))
          ..add((200, '{}'));

        final res = await dio.get<dynamic>('/app/shipments');

        expect(res.statusCode, 200);
        expect(session(), isNotNull);
        expect(expiredMsg(), isNull);
      },
    );

    test(
      'si el reintento vuelve a dar 401 es una baja real: cierra con aviso',
      () async {
        grace = const Duration(milliseconds: 100);
        await signedIn();
        adapter
          ..statusCode = 401
          ..body = revoked;

        await expectLater(
          dio.get<dynamic>('/app/shipments'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(adapter.calls, 2); // un solo reintento, nunca más
        expect(
          expiredMsg(),
          'Este dispositivo fue dado de baja. Volvé a ingresar.',
        );
        expect(session(), isNull);
      },
    );

    test('fuera de la ventana (sesión vieja) cierra sin reintentar', () async {
      await signedIn(); // grace = 0 → ya fuera de la ventana
      adapter
        ..statusCode = 401
        ..body = revoked;

      await expectLater(
        dio.get<dynamic>('/app/shipments'),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.calls, 1);
      expect(session(), isNull);
    });

    test('sin login nuevo (sesión restaurada) no hay gracia', () {
      expect(container.read(sessionProvider.notifier).freshSignInAt, isNull);
    });

    test(
      'un 401 genérico (token vencido) tras login NO se reintenta',
      () async {
        grace = const Duration(seconds: 5);
        await signedIn();
        adapter
          ..statusCode = 401
          ..body = '{"code":"unauthenticated"}';

        await expectLater(
          dio.get<dynamic>('/app/shipments'),
          throwsA(isA<DioException>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(adapter.calls, 1);
        expect(expiredMsg(), 'Tu sesión expiró, volvé a ingresar.');
        expect(session(), isNull);
      },
    );

    test(
      'si se cierra la sesión durante la espera, no reintenta ni avisa',
      () async {
        grace = const Duration(milliseconds: 150);
        await signedIn();
        adapter
          ..statusCode = 401
          ..body = revoked;

        final pending = dio.get<dynamic>('/app/shipments');
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await container.read(sessionProvider.notifier).signOut();

        await expectLater(pending, throwsA(isA<DioException>()));
        expect(adapter.calls, 1);
        expect(expiredMsg(), isNull);
      },
    );
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

  group('reuso de conexiones (HttpClient del API)', () {
    test('idleTimeout 90 s y 6 conexiones por host', () {
      final adapter = createApiHttpClientAdapter();
      final client = adapter.createHttpClient!();
      addTearDown(() => client.close(force: true));
      expect(client.idleTimeout, const Duration(seconds: 90));
      expect(client.maxConnectionsPerHost, 6);
      expect(kApiIdleTimeout, const Duration(seconds: 90));
      expect(kApiMaxConnectionsPerHost, 6);
    });

    test('dioProvider usa ese adaptador por defecto', () {
      final fresh = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
          logisticsApiProvider.overrideWithValue(
            FakeLogisticsApi(FakeAuthClient()),
          ),
        ],
      );
      addTearDown(fresh.dispose);
      final adapter = fresh.read(dioProvider).httpClientAdapter;
      expect(adapter, isA<IOHttpClientAdapter>());
      final client = (adapter as IOHttpClientAdapter).createHttpClient!();
      addTearDown(() => client.close(force: true));
      expect(client.idleTimeout, kApiIdleTimeout);
    });
  });

  group('truncateLogLine (log HTTP en debug)', () {
    test('líneas cortas quedan igual', () {
      expect(truncateLogLine('GET /app/routes'), 'GET /app/routes');
    });

    test('un body grande se recorta al tope', () {
      final line = 'x' * 5000;
      final out = truncateLogLine(line);
      expect(out.length, lessThan(kHttpLogMaxChars + 40));
      expect(out, endsWith('(+${5000 - kHttpLogMaxChars} caracteres)'));
    });
  });
}
