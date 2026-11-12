import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/conduct_pre_trip_checklist_request.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/features/driver/data/datasources/fleet_data_source.dart';

// El checklist pre-salida: el backend valida `performed_on` con
// `date_format:Y-m-d`; el cliente generado lo mandaba como fecha-hora ISO → 422
// ("performed_on must match the format Y-m-d"). El data source lo manda en Y-m-d.

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body);
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
  test(
    'conductPreTripChecklist manda performed_on en Y-m-d (no fecha-hora)',
    () async {
      final adapter = _CapturingAdapter('{"data":null}');
      final dio = Dio(BaseOptions(baseUrl: 'http://x'))
        ..httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      await container
          .read(fleetDataSourceProvider)
          .conductPreTripChecklist(
            ConductPreTripChecklistRequest(
              vehicleId: 'veh-1',
              driverId: 'drv-1',
              items: const {'frenos': true, 'luces': true},
              // Con hora a propósito: debe salir SOLO la fecha.
              performedOn: DateTime(2026, 11, 12, 15, 30, 45),
              notes: 'ok',
            ),
          );

      expect(adapter.last!.uri.path, '/app/fleet/pre-trip-checklists');
      final sent = adapter.last!.data as Map;
      expect(sent['performed_on'], '2026-11-12'); // Y-m-d, sin hora ni ISO
      expect(sent['vehicle_id'], 'veh-1');
      expect(sent['items'], {'frenos': true, 'luces': true});
    },
  );
}
