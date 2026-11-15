import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/date_body_interceptor.dart';

// Recorta a Y-m-d los campos de fecha de calendario del cuerpo (el backend los
// valida `date_format:Y-m-d`; el cliente generado manda fecha-hora ISO → 422).

RequestOptions _run(Object? data) {
  const interceptor = DateBodyInterceptor();
  final options = RequestOptions(path: '/x')..data = data;
  interceptor.onRequest(options, RequestInterceptorHandler());
  return options;
}

void main() {
  test('recorta plan_date / performed_on ISO a Y-m-d', () {
    final body =
        _run(<String, Object?>{
              'plan_date': '2026-11-12T15:30:45.000',
              'performed_on': '2026-11-12T00:00:00.000Z',
              'strategy': 'auto',
            }).data
            as Map;
    expect(body['plan_date'], '2026-11-12');
    expect(body['performed_on'], '2026-11-12');
    expect(body['strategy'], 'auto'); // no-fecha intacto
  });

  test('NO toca los campos fecha-hora (*_at) ni un Y-m-d ya correcto', () {
    final body =
        _run(<String, Object?>{
              'occurred_at': '2026-11-12T15:30:45.000',
              'read_at': '2026-11-12T15:30:45.000',
              'depart_at': '2026-11-12T08:00:00.000',
              'period_from': '2026-11-01', // ya Y-m-d
            }).data
            as Map;
    // Los *_at son fecha-hora reales: se mandan tal cual.
    expect(body['occurred_at'], '2026-11-12T15:30:45.000');
    expect(body['read_at'], '2026-11-12T15:30:45.000');
    expect(body['depart_at'], '2026-11-12T08:00:00.000');
    // Un Y-m-d ya correcto queda igual (idempotente).
    expect(body['period_from'], '2026-11-01');
  });

  test('cuerpos que no son Map no se tocan', () {
    expect(_run('texto').data, 'texto');
    expect(_run(null).data, isNull);
  });
}
