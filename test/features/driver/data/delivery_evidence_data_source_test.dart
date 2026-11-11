import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/features/driver/data/datasources/delivery_evidence_data_source.dart';
import 'package:logistics_app/features/driver/domain/entities/delivery_evidence.dart';

// Evidencia de entrega (anti-fraude): se parsea el JSON crudo del backend a la
// lista mínima para la UI (kind + estado de validación).

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);
  final String body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
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
  test('evidenceValidationFromString mapea los estados del backend', () {
    expect(evidenceValidationFromString('ok'), EvidenceValidation.ok);
    expect(evidenceValidationFromString('review'), EvidenceValidation.review);
    expect(
      evidenceValidationFromString('mismatch'),
      EvidenceValidation.mismatch,
    );
    expect(evidenceValidationFromString('pending'), EvidenceValidation.pending);
    expect(evidenceValidationFromString(null), EvidenceValidation.unknown);
    expect(evidenceValidationFromString('otra'), EvidenceValidation.unknown);
  });

  test('get() pide el endpoint del envío y parsea las evidencias', () async {
    final adapter = _JsonAdapter('''
      {"data":[
        {"id":"e1","kind":"signature","validation_status":"ok","validation_detail":null},
        {"id":"e2","kind":"id_document","validation_status":"mismatch","validation_detail":"no coincide"}
      ]}
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'http://x'))
      ..httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [dioProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);

    final items = await container
        .read(deliveryEvidenceDataSourceProvider)
        .get('ship-1');

    expect(adapter.last!.uri.path, '/app/deliveries/ship-1/evidence');
    expect(items, hasLength(2));
    expect(items[0].kind, 'signature');
    expect(items[0].status, EvidenceValidation.ok);
    expect(items[1].kind, 'id_document');
    expect(items[1].status, EvidenceValidation.mismatch);
    expect(items[1].detail, 'no coincide');
  });
}
