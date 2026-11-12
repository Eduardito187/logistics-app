import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';

// Cabecera `Retry-After` (RFC 9110): la cola offline la usa como espera MÍNIMA
// en los 429/503, así que ApiException tiene que leerla tanto en segundos como
// en fecha HTTP, y descartar lo que no sirve sin romper el parseo del error.

DioException _withRetryAfter(String? value, {int statusCode = 429}) {
  final options = RequestOptions(path: '/app/scans');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: statusCode,
      data: const {'title': 'Demasiadas solicitudes'},
      headers: Headers.fromMap({
        'content-type': ['application/problem+json'],
        if (value != null) 'retry-after': [value],
      }),
    ),
  );
}

void main() {
  group('ApiException.parseRetryAfter', () {
    test('segundos', () {
      expect(ApiException.parseRetryAfter('120'), const Duration(seconds: 120));
      expect(ApiException.parseRetryAfter(' 30 '), const Duration(seconds: 30));
    });

    test('cero o negativo no es una espera', () {
      expect(ApiException.parseRetryAfter('0'), isNull);
      expect(ApiException.parseRetryAfter('-10'), isNull);
    });

    test('fecha HTTP futura: la diferencia contra ahora', () {
      final now = DateTime.utc(2026, 11, 12, 10);
      expect(
        ApiException.parseRetryAfter('Thu, 12 Nov 2026 10:02:00 GMT', now: now),
        const Duration(minutes: 2),
      );
    });

    test('fecha HTTP ya pasada: no se espera', () {
      final now = DateTime.utc(2026, 11, 12, 10);
      expect(
        ApiException.parseRetryAfter('Thu, 12 Nov 2026 09:00:00 GMT', now: now),
        isNull,
      );
    });

    test('vacía, ausente o ilegible: null', () {
      expect(ApiException.parseRetryAfter(null), isNull);
      expect(ApiException.parseRetryAfter(''), isNull);
      expect(ApiException.parseRetryAfter('   '), isNull);
      expect(ApiException.parseRetryAfter('cuando quieras'), isNull);
    });
  });

  group('ApiException.fromDio', () {
    test('429 con Retry-After en segundos lo expone', () {
      final e = ApiException.fromDio(_withRetryAfter('45'));
      expect(e.status, 429);
      expect(e.isRateLimited, isTrue);
      expect(e.retryAfter, const Duration(seconds: 45));
    });

    test('503 con Retry-After lo expone igual', () {
      final e = ApiException.fromDio(_withRetryAfter('15', statusCode: 503));
      expect(e.status, 503);
      expect(e.retryAfter, const Duration(seconds: 15));
    });

    test('sin la cabecera queda null (manda el backoff propio)', () {
      final e = ApiException.fromDio(_withRetryAfter(null));
      expect(e.retryAfter, isNull);
      // El resto del parseo RFC 7807 no se altera.
      expect(e.title, 'Demasiadas solicitudes');
    });

    test('cabecera basura: null, sin romper el error', () {
      final e = ApiException.fromDio(_withRetryAfter('ya veremos'));
      expect(e.retryAfter, isNull);
      expect(e.status, 429);
    });

    test('sin respuesta (sin red) no hay cabecera que leer', () {
      final e = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/app/scans'),
          type: DioExceptionType.connectionError,
        ),
      );
      expect(e.retryAfter, isNull);
      expect(e.isConnectionError, isTrue);
    });
  });
}
