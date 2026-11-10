import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/features/picking/data/datasources/picking_remote_data_source.dart';

// El filtro por estado del preparador va en el SERVIDOR: se verifica la URL
// real que arma el cliente generado.

class _CaptureAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode({'data': <Object>[]}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('listShipments manda el estado pedido como filtro', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter;
    final source = PickingRemoteDataSource(LogisticsApi(dio), dio);

    await source.listShipments(status: ShipmentStatus.planned);

    final uri = adapter.requests.single.uri;
    expect(uri.path, '/app/shipments');
    expect(uri.queryParameters['status'], 'PLANNED');
  });

  test(
    'emitOrderLabels hace POST con body vacío al endpoint del pedido',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
        ..httpClientAdapter = adapter;
      final source = PickingRemoteDataSource(LogisticsApi(dio), dio);

      await source.emitOrderLabels('SCZ-1');

      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.uri.path, '/app/orders/SCZ-1/labels');
      // Body vacío: el backend deriva origen/destino/líneas (emisión por orden).
      expect(req.data, isEmpty);
    },
  );
}
