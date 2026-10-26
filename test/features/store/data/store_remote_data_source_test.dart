import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/features/store/data/datasources/store_remote_data_source.dart';

// El filtro por tienda va en el SERVIDOR: se verifica la URL real que arma el
// cliente generado (Dio con un adaptador que captura el request).

/// Adaptador HTTP que registra cada request y responde una colección vacía.
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

({StoreRemoteDataSource source, _CaptureAdapter adapter}) _wire() {
  final adapter = _CaptureAdapter();
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
    ..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [logisticsApiProvider.overrideWithValue(LogisticsApi(dio))],
  );
  addTearDown(container.dispose);
  return (
    source: container.read(storeRemoteDataSourceProvider),
    adapter: adapter,
  );
}

void main() {
  test('listShipments manda destination_node_id de la tienda', () async {
    final w = _wire();

    await w.source.listShipments(destinationNodeId: 'node-store');

    final uri = w.adapter.requests.single.uri;
    expect(uri.path, '/app/shipments');
    expect(uri.queryParameters['destination_node_id'], 'node-store');
  });

  test('sin tienda no inventa el filtro', () async {
    final w = _wire();

    await w.source.listShipments();

    final uri = w.adapter.requests.single.uri;
    expect(uri.queryParameters.containsKey('destination_node_id'), isFalse);
  });
}
