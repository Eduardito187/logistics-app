import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/null_body_strip_interceptor.dart';

// El interceptor que omite los campos opcionales en `null` del cuerpo: el
// backend valida varios con `sometimes|string` (sin `nullable`) y un `null`
// explícito da 422 (causa del POD que no se registraba).

RequestOptions _run(Object? data) {
  const interceptor = NullBodyStripInterceptor();
  final options = RequestOptions(path: '/app/deliveries/proof-of-delivery');
  options.data = data;
  interceptor.onRequest(options, RequestInterceptorHandler());
  return options;
}

void main() {
  test('quita las claves de nivel superior con valor null', () {
    final options = _run(<String, Object?>{
      'shipment_id': 'abc',
      'unit_id': 'u-1',
      'lat': 0,
      'lng': 0,
      'confirmation': 'FIRMA_DIGITAL',
      'device_id': null,
      'user_id': null,
      'idempotency_key': null,
      'photo_url': null,
      'photo_path': null,
    });

    final body = options.data as Map;
    // Quedan solo los campos con valor; los null (device_id/user_id/… ) fuera.
    expect(
      body.keys,
      containsAll(<String>[
        'shipment_id',
        'unit_id',
        'lat',
        'lng',
        'confirmation',
      ]),
    );
    expect(body.containsKey('device_id'), isFalse);
    expect(body.containsKey('user_id'), isFalse);
    expect(body.containsKey('photo_path'), isFalse);
    expect(body.containsKey('photo_url'), isFalse);
    expect(body.containsKey('idempotency_key'), isFalse);
  });

  test('conserva los valores presentes, incluido 0 y false', () {
    final options = _run(<String, Object?>{
      'lat': 0,
      'lng': 0.0,
      'flag': false,
      'txt': '',
      'n': null,
    });
    final body = options.data as Map;
    expect(body['lat'], 0);
    expect(body['lng'], 0.0);
    expect(body['flag'], false);
    expect(body['txt'], '');
    expect(body.containsKey('n'), isFalse);
  });

  test('solo toca el primer nivel: los mapas anidados quedan igual', () {
    final options = _run(<String, Object?>{
      'device': <String, Object?>{'fingerprint': 'fp', 'push_token': null},
      'x': null,
    });
    final body = options.data as Map;
    expect(body.containsKey('x'), isFalse);
    final device = body['device'] as Map;
    // El null ANIDADO no se toca (solo el primer nivel).
    expect(device.containsKey('push_token'), isTrue);
    expect(device['push_token'], isNull);
  });

  test('cuerpos que no son Map no se tocan (FormData, string, null)', () {
    expect(_run('texto plano').data, 'texto plano');
    expect(_run(null).data, isNull);
    final form = FormData();
    expect(_run(form).data, same(form));
  });
}
