import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/date_query_interceptor.dart';

void main() {
  group('DateQueryInterceptor', () {
    test('recorta una fecha de calendario (medianoche local) a Y-m-d', () {
      final value = DateTime(2026, 10, 19).toIso8601String();
      expect(value, '2026-10-19T00:00:00.000');
      expect(DateQueryInterceptor.normalize(value), '2026-10-19');
    });

    test('no toca instantes con zona ni horas distintas de medianoche', () {
      final utc = DateTime.utc(2026, 10, 19).toIso8601String();
      expect(DateQueryInterceptor.normalize(utc), utc);
      const withTime = '2026-10-19T08:30:00.000';
      expect(DateQueryInterceptor.normalize(withTime), withTime);
      expect(DateQueryInterceptor.normalize('2026-10-19'), '2026-10-19');
      expect(DateQueryInterceptor.normalize(42), 42);
      expect(DateQueryInterceptor.normalize(null), isNull);
    });

    test('reescribe el query del request de my-crew', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..interceptors.add(const DateQueryInterceptor());
      late RequestOptions sent;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(Response(requestOptions: options, statusCode: 200));
          },
        ),
      );

      await dio.get<void>(
        '/app/fleet/my-crew',
        queryParameters: {
          'date': DateTime(2026, 10, 19).toIso8601String(),
          'vehicle_id': 'abc',
        },
      );

      expect(sent.queryParameters, {'date': '2026-10-19', 'vehicle_id': 'abc'});
      expect(sent.uri.query, 'date=2026-10-19&vehicle_id=abc');
    });
  });
}
