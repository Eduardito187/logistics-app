// Dobles compartidos por los tests de sincronización (colas offline, purga,
// tarea de fondo y cierre de sesión). Sin mocking: implementan la interfaz real
// y resuelven lo no usado vía noSuchMethod.

import 'package:dio/dio.dart';
import 'package:logistics_app/core/api/clients/execution_client.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/api/models/data.dart';
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/delivery_status.dart';
import 'package:logistics_app/core/api/models/kind.dart';
import 'package:logistics_app/core/api/models/post_app_deliveries_photos_response.dart';
import 'package:logistics_app/core/api/models/post_app_deliveries_scans_load_response.dart';
import 'package:logistics_app/core/background/sync_scheduler.dart';
import 'package:logistics_app/core/offline/failure_reporter.dart';

const _loadOk = PostAppDeliveriesScansLoadResponse(
  data: Delivery(
    id: 'd1',
    shipmentId: 's1',
    vehicleId: 'v1',
    status: DeliveryStatus.loaded,
    scans: [],
  ),
);

const _photoOk = PostAppDeliveriesPhotosResponse(
  data: Data(kind: Kind.pod, disk: 'local', path: 'p/1.jpg', url: null),
);

/// Cliente de ejecución guionizado: cada llamada (escaneo de carga o subida de
/// foto) consume un paso (`null` = éxito, un [DioException] = se lanza).
/// Agotado el guion, responde éxito.
class ScriptedExecution implements ExecutionClient {
  ScriptedExecution([List<DioException?> script = const []])
    : _script = List.of(script);

  final List<DioException?> _script;
  int calls = 0;
  int photoCalls = 0;

  /// Agrega pasos al guion.
  void enqueue(List<DioException?> steps) => _script.addAll(steps);

  DioException? _next() => _script.isNotEmpty ? _script.removeAt(0) : null;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    if (invocation.memberName == #uploadDeliveryPhoto) {
      photoCalls++;
      return Future<PostAppDeliveriesPhotosResponse>(() async {
        final step = _next();
        if (step != null) throw step;
        return _photoOk;
      });
    }
    return Future<PostAppDeliveriesScansLoadResponse>(() async {
      final step = _next();
      if (step != null) throw step;
      return _loadOk;
    });
  }
}

/// LogisticsApi falso que expone el [ExecutionClient] inyectado.
class FakeSyncApi extends LogisticsApi {
  FakeSyncApi(this._execution) : super(Dio());
  final ExecutionClient _execution;
  @override
  ExecutionClient get execution => _execution;
}

/// Reporter que guarda los eventos.
class RecordingReporter implements FailureReporter {
  final List<OutboxFailure> events = [];
  bool throwOnReport = false;

  @override
  Future<void> report(OutboxFailure failure) async {
    if (throwOnReport) throw StateError('reporter roto');
    events.add(failure);
  }
}

/// Planificador que cuenta los pedidos de tarea única.
class CountingScheduler implements SyncScheduler {
  int oneOffs = 0;
  @override
  Future<void> scheduleOneOff() async => oneOffs++;
}

DioException connectionError() => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);

DioException httpError(int code, {String? problemCode}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
    data: {
      'title': 'Error',
      'detail': 'Juan Pérez, CI 123 (dato personal que no debe reportarse)',
      'code': ?problemCode,
    },
  ),
);

/// Payload válido para `recordLoadScan`.
Map<String, Object?> scanPayload() => {
  'shipment_id': 's1',
  'unit_id': 'u1',
  'lat': -16.5,
  'lng': -68.1,
  'occurred_at': '2026-10-15T12:00:00.000Z',
};
