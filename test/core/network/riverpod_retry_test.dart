import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/core/network/riverpod_retry.dart';

// Política de reintento de providers: solo lo transitorio (conexión/timeout,
// 5xx, 429), máximo 3 veces con backoff 400 ms · 2^n; 4xx nunca.

ApiException _status(int status) =>
    ApiException(status: status, title: 'Error');

const _offline = ApiException(
  status: 0,
  title: 'Sin conexión',
  isConnectionError: true,
);

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
  response: status == null
      ? null
      : Response<Object?>(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: status,
        ),
);

void main() {
  group('appProviderRetry — transitorios', () {
    test('sin conexión: backoff 400, 800, 1600 ms y corta en el 4.º', () {
      expect(appProviderRetry(0, _offline), const Duration(milliseconds: 400));
      expect(appProviderRetry(1, _offline), const Duration(milliseconds: 800));
      expect(appProviderRetry(2, _offline), const Duration(milliseconds: 1600));
      expect(appProviderRetry(3, _offline), isNull);
      expect(appProviderRetry(10, _offline), isNull);
    });

    test('5xx y 429 se reintentan', () {
      expect(appProviderRetry(0, _status(500)), isNotNull);
      expect(appProviderRetry(0, _status(503)), isNotNull);
      expect(appProviderRetry(0, _status(429)), isNotNull);
    });

    test('DioException crudo: timeout, conexión y 502 se reintentan', () {
      expect(
        appProviderRetry(0, _dio(DioExceptionType.connectionTimeout)),
        isNotNull,
      );
      expect(
        appProviderRetry(0, _dio(DioExceptionType.receiveTimeout)),
        isNotNull,
      );
      expect(
        appProviderRetry(0, _dio(DioExceptionType.connectionError)),
        isNotNull,
      );
      expect(
        appProviderRetry(0, _dio(DioExceptionType.badResponse, status: 502)),
        isNotNull,
      );
    });
  });

  group('appProviderRetry — permanentes (sin reintento)', () {
    test('403, 404, 422, 400 y 401 → null', () {
      for (final status in [400, 401, 403, 404, 409, 422]) {
        expect(appProviderRetry(0, _status(status)), isNull, reason: '$status');
      }
    });

    test('DioException 404 crudo → null', () {
      expect(
        appProviderRetry(0, _dio(DioExceptionType.badResponse, status: 404)),
        isNull,
      );
    });

    test('errores ajenos a la red → null', () {
      expect(appProviderRetry(0, StateError('bug')), isNull);
      expect(appProviderRetry(0, const FormatException('json')), isNull);
      expect(appProviderRetry(0, Exception('x')), isNull);
    });
  });

  group('cableado en un ProviderContainer', () {
    test('un 404 no se reintenta: el provider corre una sola vez', () async {
      var runs = 0;
      final provider = FutureProvider<int>((ref) async {
        runs++;
        throw _status(404);
      });
      final container = ProviderContainer(retry: appProviderRetry);
      addTearDown(container.dispose);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      await expectLater(container.read(provider.future), throwsA(anything));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(runs, 1);
    });

    test('sin conexión se reintenta y se recupera', () async {
      var runs = 0;
      final provider = FutureProvider<int>((ref) async {
        runs++;
        if (runs == 1) throw _offline;
        return 42;
      });
      final container = ProviderContainer(retry: appProviderRetry);
      addTearDown(container.dispose);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(runs, 2);
      expect(container.read(provider).value, 42);
    });
  });
}
