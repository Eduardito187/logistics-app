import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/execution_client.dart';
import 'package:logistics_app/core/api/clients/tracking_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/app_vehicles_vehicle_id_incidents_request_body.dart';
import 'package:logistics_app/core/api/models/failed_delivery_request.dart';
import 'package:logistics_app/core/api/models/node_reception_request.dart';
import 'package:logistics_app/core/api/models/preparation_scan_request.dart';
import 'package:logistics_app/core/api/models/proof_of_delivery_request.dart';
import 'package:logistics_app/core/api/models/receive_unit_at_node_request.dart';
import 'package:logistics_app/core/api/models/scan_request.dart';
import 'package:logistics_app/core/api/models/truck_position_input.dart';
import 'package:logistics_app/core/api/models/unload_scan_request.dart';
import 'package:logistics_app/core/offline/offline_dispatcher.dart';

/// Registra la última invocación. Cada cliente falso, tras registrar, lanza un
/// DioException (vía `Future<Never>.error`, que casa con cualquier tipo de
/// retorno) para no tener que construir respuestas tipadas.
class _Recorder {
  Symbol? member;
  Map<Symbol, Object?> named = const {};
}

final _boom = DioException(requestOptions: RequestOptions(path: '/x'));

class _RecordingExecution implements ExecutionClient {
  _RecordingExecution(this._rec);
  final _Recorder _rec;
  @override
  dynamic noSuchMethod(Invocation i) {
    _rec.member = i.memberName;
    _rec.named = i.namedArguments;
    return Future<Never>.error(_boom);
  }
}

class _RecordingTracking implements TrackingClient {
  _RecordingTracking(this._rec);
  final _Recorder _rec;
  @override
  dynamic noSuchMethod(Invocation i) {
    _rec.member = i.memberName;
    _rec.named = i.namedArguments;
    return Future<Never>.error(_boom);
  }
}

class _RecordingApi extends LogisticsApi {
  _RecordingApi(this.execRec, this.trackRec) : super(Dio());
  final _Recorder execRec;
  final _Recorder trackRec;
  @override
  ExecutionClient get execution => _RecordingExecution(execRec);
  @override
  TrackingClient get tracking => _RecordingTracking(trackRec);
}

Map<String, Object?> _scanBase() => {
  'shipment_id': 's1',
  'unit_id': 'u1',
  'lat': -16.5,
  'lng': -68.1,
  'occurred_at': '2026-10-15T12:00:00.000Z',
};

void main() {
  late _Recorder execRec;
  late _Recorder trackRec;
  late _RecordingApi api;

  setUp(() {
    execRec = _Recorder();
    trackRec = _Recorder();
    api = _RecordingApi(execRec, trackRec);
  });

  /// Corre el handler de [kind] con [payload] y espera a que (tras registrar)
  /// propague el DioException del doble.
  Future<void> run(String kind, Map<String, Object?> payload) async {
    await expectLater(
      offlineHandlers[kind]!(api, 'KEY-1', payload),
      throwsA(isA<DioException>()),
    );
  }

  group('offlineHandlers — contrato del mapa', () {
    test('contiene exactamente las claves esperadas', () {
      expect(offlineHandlers.keys.toSet(), {
        'recordPreparationScan',
        'recordLoadScan',
        'recordUnloadScan',
        'recordFailedDelivery',
        'recordProofOfDelivery',
        'reportVehicleIncident',
        'reportDeliveryIssue',
        'updateDevicePushToken',
        'ingestTruckPosition',
        'recordNodeReception',
        'receiveUnitAtNode',
      });
    });

    test('un kind inexistente no está en el mapa', () {
      expect(offlineHandlers['noExiste'], isNull);
    });
  });

  group('cada kind mapea al método correcto del cliente', () {
    test(
      'recordLoadScan → execution.recordLoadScan(ScanRequest, key)',
      () async {
        await run('recordLoadScan', _scanBase());
        expect(execRec.member, #recordLoadScan);
        expect(execRec.named[#body], isA<ScanRequest>());
        expect(execRec.named[#idempotencyKey], 'KEY-1');
      },
    );

    test(
      'recordUnloadScan → execution.recordUnloadScan(UnloadScanRequest)',
      () async {
        await run('recordUnloadScan', {..._scanBase(), 'node_id': 'n1'});
        expect(execRec.member, #recordUnloadScan);
        expect(execRec.named[#body], isA<UnloadScanRequest>());
        expect(execRec.named[#idempotencyKey], 'KEY-1');
      },
    );

    test('recordPreparationScan → execution.recordPreparationScan', () async {
      await run('recordPreparationScan', {..._scanBase(), 'vehicle_id': 'v1'});
      expect(execRec.member, #recordPreparationScan);
      expect(execRec.named[#body], isA<PreparationScanRequest>());
      expect(execRec.named[#idempotencyKey], 'KEY-1');
    });

    test('recordFailedDelivery → execution.recordFailedDelivery', () async {
      await run('recordFailedDelivery', {
        ..._scanBase(),
        'reason': 'CUSTOMER_ABSENT',
      });
      expect(execRec.member, #recordFailedDelivery);
      expect(execRec.named[#body], isA<FailedDeliveryRequest>());
      expect(execRec.named[#idempotencyKey], 'KEY-1');
    });

    test('recordProofOfDelivery → execution.recordProofOfDelivery', () async {
      await run('recordProofOfDelivery', {
        ..._scanBase(),
        'confirmation': 'OK',
      });
      expect(execRec.member, #recordProofOfDelivery);
      expect(execRec.named[#body], isA<ProofOfDeliveryRequest>());
      expect(execRec.named[#idempotencyKey], 'KEY-1');
    });

    test('recordNodeReception → execution.recordNodeReception', () async {
      await run('recordNodeReception', {..._scanBase(), 'node_id': 'n1'});
      expect(execRec.member, #recordNodeReception);
      expect(execRec.named[#body], isA<NodeReceptionRequest>());
      expect(execRec.named[#idempotencyKey], 'KEY-1');
    });

    test('receiveUnitAtNode → execution.receiveUnitAtNode', () async {
      await run('receiveUnitAtNode', {
        ..._scanBase(),
        'destination_node_id': 'n2',
      });
      expect(execRec.member, #receiveUnitAtNode);
      expect(execRec.named[#body], isA<ReceiveUnitAtNodeRequest>());
      expect(execRec.named[#idempotencyKey], 'KEY-1');
    });

    test(
      'reportVehicleIncident → execution.reportVehicleIncident con @vehicleId',
      () async {
        await run('reportVehicleIncident', {
          '@vehicleId': 'veh-9',
          'severity': 'MINOR',
          'type': 'BREAKDOWN',
        });
        expect(execRec.member, #reportVehicleIncident);
        expect(execRec.named[#vehicleId], 'veh-9');
        expect(
          execRec.named[#body],
          isA<AppVehiclesVehicleIdIncidentsRequestBody>(),
        );
        expect(execRec.named[#idempotencyKey], 'KEY-1');
      },
    );

    test(
      'ingestTruckPosition → tracking.ingestTruckPositionFromApp con @shipmentId',
      () async {
        await run('ingestTruckPosition', {
          '@shipmentId': 'sh-7',
          'lat': -16.5,
          'lng': -68.1,
          'reported_at': '2026-10-15T12:00:00.000Z',
        });
        expect(trackRec.member, #ingestTruckPositionFromApp);
        expect(trackRec.named[#shipmentId], 'sh-7');
        expect(trackRec.named[#body], isA<TruckPositionInput>());
        // Nota: por diseño (GPS de alta frecuencia) este handler NO reenvía la
        // Idempotency-Key; no debe esperarse en los argumentos.
        expect(trackRec.named.containsKey(#idempotencyKey), isFalse);
      },
    );
  });
}
