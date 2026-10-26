import 'package:dio/dio.dart';

/// Normaliza los parámetros de fecha del query string al formato `Y-m-d` que
/// espera el backend.
///
/// El cliente generado (retrofit) serializa todo `DateTime` del query con
/// `toIso8601String()`, así que una fecha de calendario (`format: date` en el
/// OpenAPI: `date`, `from`, `to`, `reference_date`...) sale como
/// `2026-10-19T00:00:00.000` y Laravel la rechaza con 422. Como el cliente no
/// se edita a mano, se corrige acá: un valor a medianoche LOCAL exacta y sin
/// zona horaria es una fecha de calendario y se recorta a `2026-10-19`.
/// Los instantes reales (con `Z`/offset u hora distinta de 00:00) no se tocan.
class DateQueryInterceptor extends Interceptor {
  const DateQueryInterceptor();

  static final _localMidnight = RegExp(
    r'^(\d{4}-\d{2}-\d{2})T00:00:00(\.0+)?$',
  );

  /// Devuelve el valor con la fecha recortada si es una medianoche local.
  static Object? normalize(Object? value) {
    if (value is String) {
      final match = _localMidnight.firstMatch(value);
      if (match != null) return match.group(1);
    }
    return value;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.queryParameters.isNotEmpty) {
      options.queryParameters = options.queryParameters.map(
        (key, value) => MapEntry(key, normalize(value)),
      );
    }
    handler.next(options);
  }
}
