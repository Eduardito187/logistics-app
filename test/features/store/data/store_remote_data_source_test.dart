import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/features/store/data/datasources/store_remote_data_source.dart';

import '../store_fixtures.dart';

// El filtro por tienda va en el SERVIDOR: se verifica la URL real que arma el
// cliente generado (Dio con un adaptador que captura el request).

/// Adaptador HTTP que registra cada request y responde [body] (por defecto una
/// colección vacía).
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter({Map<String, Object?>? body})
    : body = body ?? {'data': <Object>[]};

  final List<RequestOptions> requests = [];
  final Map<String, Object?> body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({StoreRemoteDataSource source, _CaptureAdapter adapter}) _wire({
  Map<String, Object?>? body,
}) {
  final adapter = _CaptureAdapter(body: body);
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

  group('listShipmentsPage', () {
    test('manda page y per_page (sin ellos se perdía del 51 en más)', () async {
      final w = _wire();

      await w.source.listShipmentsPage(
        destinationNodeId: 'node-store',
        page: 3,
        perPage: 50,
      );

      final uri = w.adapter.requests.single.uri;
      expect(uri.path, '/app/shipments');
      expect(uri.queryParameters['page'], '3');
      expect(uri.queryParameters['per_page'], '50');
      expect(uri.queryParameters['destination_node_id'], 'node-store');
    });

    test('una página completa se toma como "puede haber más"', () async {
      final w = _wire(
        body: {
          'data': [shipment().toJson(), shipment(id: 'ship-2').toJson()],
        },
      );

      final page = await w.source.listShipmentsPage(page: 1, perPage: 2);

      expect(page.shipments, hasLength(2));
      expect(page.hasMore, isTrue);
    });

    test('una página a medias es la última', () async {
      final w = _wire(
        body: {
          'data': [shipment().toJson()],
        },
      );

      final page = await w.source.listShipmentsPage(page: 1, perPage: 2);

      expect(page.hasMore, isFalse);
    });

    test('con `meta` legible manda lo que diga next_page', () async {
      // El modelo generado `MetaSealed` lee las claves en camelCase, así que
      // el `meta` real (snake_case) del backend NO encaja y se usa el
      // heurístico de tamaño. Acá se manda en camelCase para cubrir la rama
      // que SÍ mira `meta`: dice "última página" aunque venga completa.
      final w = _wire(
        body: {
          'data': [shipment().toJson(), shipment(id: 'ship-2').toJson()],
          'meta': {
            'count': 2,
            'page': 1,
            'perPage': 2,
            'total': 2,
            'totalPages': 1,
            'nextPage': null,
            'prevPage': null,
          },
        },
      );

      final page = await w.source.listShipmentsPage(page: 1, perPage: 2);

      expect(page.hasMore, isFalse);
    });
  });
}
