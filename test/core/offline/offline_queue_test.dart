import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/clients/execution_client.dart';
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/delivery_status.dart';
import 'package:logistics_app/core/api/models/post_app_deliveries_scans_load_response.dart';
import 'package:logistics_app/core/api/logistics_api.dart';
import 'package:logistics_app/core/network/dio_client.dart';
import 'package:logistics_app/core/offline/app_database.dart';
// offline_queue.dart reexporta submit_outcome.dart (SubmitOutcome).
import 'package:logistics_app/core/offline/offline_queue.dart';

// --- Dobles de prueba ------------------------------------------------------

/// Respuesta de éxito tipada para `recordLoadScan`. Los tests de OfflineQueue
/// solo encolan `recordLoadScan`, así que basta una respuesta de este tipo.
const _loadOk = PostAppDeliveriesScansLoadResponse(
  data: Delivery(
    id: 'd1',
    shipmentId: 's1',
    vehicleId: 'v1',
    status: DeliveryStatus.loaded,
    scans: [],
  ),
);

/// Cliente de ejecución falso guionizado: cada llamada consume un paso del
/// guion (`null` = éxito, un [DioException] = se lanza). Agotado el guion,
/// responde éxito. `Future<...>` tipado para que el reenvío del noSuchMethod
/// case bien al tipo de retorno declarado de `recordLoadScan`.
class _FakeExecution implements ExecutionClient {
  _FakeExecution(List<DioException?> script, {this.onCall})
    : _script = List.of(script);

  final List<DioException?> _script;
  final Future<void> Function()? onCall;

  /// Idempotency-Key recibida en cada llamada (en orden).
  final List<String?> idempotencyKeys = [];
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    idempotencyKeys.add(invocation.namedArguments[#idempotencyKey] as String?);
    return Future<PostAppDeliveriesScansLoadResponse>(() async {
      await onCall?.call();
      final step = _script.isNotEmpty ? _script.removeAt(0) : null;
      if (step != null) throw step;
      return _loadOk;
    });
  }
}

/// LogisticsApi falso que expone el [ExecutionClient] inyectado.
class _FakeApi extends LogisticsApi {
  _FakeApi(this._execution) : super(Dio());
  final ExecutionClient _execution;
  @override
  ExecutionClient get execution => _execution;
}

// --- Fábricas de errores ---------------------------------------------------

DioException _connectionError() => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);

DioException _httpError(int code, {Map<String, Object?>? body}) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.badResponse,
  response: Response<Object?>(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: code,
    data: body ?? {'title': 'Error', 'detail': 'detalle'},
  ),
);

// --- Payload válido para ScanRequest (recordLoadScan) ----------------------

Map<String, Object?> _scanPayload() => {
  'shipment_id': 's1',
  'unit_id': 'u1',
  'lat': -16.5,
  'lng': -68.1,
  'occurred_at': '2026-10-15T12:00:00.000Z',
};

void main() {
  late AppDatabase db;
  late _FakeExecution exec;
  late ProviderContainer container;
  late OfflineQueue queue;

  /// Arma el contenedor con la BD en memoria y el API falso ya inyectados.
  void build(_FakeExecution e) {
    exec = e;
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        logisticsApiProvider.overrideWithValue(_FakeApi(e)),
      ],
    );
    queue = container.read(offlineQueueProvider);
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<OutboxAction>> rows() => db.select(db.outboxActions).get();

  Future<SubmitOutcome> submitScan({String? key}) => queue.submit(
    kind: 'recordLoadScan',
    payload: _scanPayload(),
    label: 'Carga',
    idempotencyKey: key,
  );

  group('submit — camino en línea (happy path)', () {
    test(
      'éxito → SubmitOutcome.sent y la fila se borra (markSynced)',
      () async {
        build(_FakeExecution(const []));
        final outcome = await submitScan();
        expect(outcome, SubmitOutcome.sent);
        expect(exec.calls, 1);
        expect(await rows(), isEmpty);
      },
    );

    test(
      'persiste ANTES del POST: la fila ya existe cuando corre el handler',
      () async {
        var pendingDuringCall = -1;
        build(
          _FakeExecution(
            const [],
            onCall: () async {
              pendingDuringCall = (await db.pendingActions()).length;
            },
          ),
        );
        await submitScan(key: 'K1');
        // Durante el POST la acción ya estaba persistida como pendiente.
        expect(pendingDuringCall, 1);
      },
    );

    test('inyecta idempotency_key = id en el payload persistido', () async {
      // Falla sin red para conservar la fila y poder leer su payload.
      build(_FakeExecution([_connectionError()]));
      await submitScan(key: 'KEY-123');
      final payload =
          jsonDecode((await rows()).single.payload) as Map<String, Object?>;
      expect(payload['idempotency_key'], 'KEY-123');
    });

    test('pasa la Idempotency-Key (= id) al cliente del API', () async {
      build(_FakeExecution(const []));
      await submitScan(key: 'KEY-XYZ');
      expect(exec.idempotencyKeys, <String?>['KEY-XYZ']);
    });
  });

  group('submit — sin red', () {
    test(
      'isConnectionError → SubmitOutcome.queued y queda pendiente',
      () async {
        build(_FakeExecution([_connectionError()]));
        final outcome = await submitScan(key: 'K1');
        expect(outcome, SubmitOutcome.queued);
        final row = (await rows()).single;
        expect(row.status, 'pending');
        expect(row.lastError, isNull);
      },
    );
  });

  group('submit — errores con respuesta del servidor', () {
    test('4xx (400) no-conexión → markFailed y SubmitOutcome.failed', () async {
      build(
        _FakeExecution([
          _httpError(400, body: {'detail': 'Dato malo'}),
        ]),
      );
      final outcome = await submitScan(key: 'K1');
      expect(outcome, SubmitOutcome.failed);
      final row = (await rows()).single;
      expect(row.status, 'failed');
      expect(row.lastError, 'Dato malo');
    });

    test('422 de validación → markFailed y failed', () async {
      build(_FakeExecution([_httpError(422)]));
      expect(await submitScan(key: 'K1'), SubmitOutcome.failed);
      expect((await rows()).single.status, 'failed');
    });

    // Un 429 es transitorio (rate limit): NO es culpa del dato, así que la fila
    // queda `pending` para reintentar (no se pierde la escritura de terreno).
    test('429 (rate limit) → SubmitOutcome.queued y queda pendiente', () async {
      build(_FakeExecution([_httpError(429)]));
      expect(await submitScan(key: 'K1'), SubmitOutcome.queued);
      final row = (await rows()).single;
      expect(row.status, 'pending');
    });

    // Un 5xx es transitorio (servidor caído): igual que el 429, queda pendiente
    // para reintento; nunca se marca `failed` permanente.
    test('5xx (503) → SubmitOutcome.queued y queda pendiente', () async {
      build(_FakeExecution([_httpError(503)]));
      expect(await submitScan(key: 'K1'), SubmitOutcome.queued);
      final row = (await rows()).single;
      expect(row.status, 'pending');
    });
  });

  group('submit — idempotencia', () {
    test('reenviar con la misma key (sin red) no duplica la fila', () async {
      build(_FakeExecution([_connectionError(), _connectionError()]));
      await submitScan(key: 'SAME');
      await submitScan(key: 'SAME');
      // insertOrIgnore evita la duplicación: una sola fila pendiente.
      expect(await rows(), hasLength(1));
      expect((await rows()).single.id, 'SAME');
    });
  });

  group('submit — kind desconocido', () {
    test('lanza StateError (no ApiException) y no lo captura submit', () async {
      build(_FakeExecution(const []));
      await expectLater(
        queue.submit(kind: 'noExiste', payload: {}, label: 'x'),
        throwsA(isA<StateError>()),
      );
      // El API nunca se invocó.
      expect(exec.calls, 0);
    });

    // El kind se valida ANTES de persistir: un kind desconocido lanza StateError
    // y NO deja fila encolada (antes dejaba una fila "pending" envenenada que
    // luego rompía el drain).
    test('no deja ninguna fila encolada tras el StateError', () async {
      build(_FakeExecution(const []));
      await queue
          .submit(kind: 'noExiste', payload: {}, label: 'x')
          .catchError((_) => SubmitOutcome.failed);
      expect(await rows(), isEmpty);
    });
  });

  group('drain', () {
    /// Encola directamente una acción con estado controlado.
    Future<void> seed(String id, {String status = 'pending'}) {
      return db.enqueue(
        OutboxActionsCompanion.insert(
          id: id,
          kind: 'recordLoadScan',
          payload: jsonEncode(_scanPayload()),
          occurredAt: DateTime.utc(2026, 1, 1),
          status: Value(status),
        ),
      );
    }

    test('reintenta las pendientes y borra las que suben bien', () async {
      build(_FakeExecution(const [null, null]));
      await seed('a');
      await seed('b');
      await queue.drain();
      expect(exec.calls, 2);
      expect(await rows(), isEmpty);
    });

    test(
      'corta en el primer isConnectionError (break) y deja el resto',
      () async {
        build(_FakeExecution([_connectionError()]));
        await seed('a'); // se procesa primero (orden por id asc) → sin red
        await seed('b'); // no se llega a procesar
        await queue.drain();
        expect(exec.calls, 1);
        final ids = (await rows()).map((r) => r.id).toSet();
        expect(ids, {'a', 'b'}); // ambas siguen pendientes
        expect((await rows()).every((r) => r.status == 'pending'), isTrue);
      },
    );

    test('markFailed en un 4xx y CONTINÚA con la siguiente', () async {
      build(
        _FakeExecution([
          _httpError(400, body: {'detail': 'malo'}),
          null,
        ]),
      );
      await seed('a'); // 4xx → failed
      await seed('b'); // éxito → borrada
      await queue.drain();
      expect(exec.calls, 2);
      final remaining = await rows();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, 'a');
      expect(remaining.single.status, 'failed');
      expect(remaining.single.lastError, 'malo');
    });

    // FALENCIA DETECTADA (offline_queue.dart:107-115): `_run` lanza StateError
    // para un kind desconocido, y el `catch` de drain ahora atrapa StateError.
    // Una fila con kind removido/obsoleto se aísla (markFailed) y el drenado
    // sigue con las demás (antes rompía todo el drain en silencio).
    test(
      'un kind desconocido no frena el drenado (se aísla la fila)',
      () async {
        build(_FakeExecution(const [null]));
        await db.enqueue(
          OutboxActionsCompanion.insert(
            id: 'a',
            kind: 'kindRemovido',
            payload: '{}',
            occurredAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await seed('b'); // válida: debería sincronizarse igual

        await queue.drain();

        // 'a' aislada como failed, 'b' sincronizada (borrada).
        final remaining = await rows();
        expect(remaining.map((r) => r.id), <String>['a']);
        expect(remaining.single.status, 'failed');
      },
    );
  });

  group('retryFailed', () {
    test('vuelve a pending, drena y si sube bien borra la fila', () async {
      build(_FakeExecution(const [null]));
      await db.enqueue(
        OutboxActionsCompanion.insert(
          id: 'a',
          kind: 'recordLoadScan',
          payload: jsonEncode(_scanPayload()),
          occurredAt: DateTime.utc(2026, 1, 1),
          status: const Value('failed'),
        ),
      );
      await queue.retryFailed('a');
      expect(exec.calls, 1);
      expect(await rows(), isEmpty);
    });

    test('si vuelve a fallar con 4xx queda failed de nuevo', () async {
      build(
        _FakeExecution([
          _httpError(400, body: {'detail': 'otra vez'}),
        ]),
      );
      await db.enqueue(
        OutboxActionsCompanion.insert(
          id: 'a',
          kind: 'recordLoadScan',
          payload: jsonEncode(_scanPayload()),
          occurredAt: DateTime.utc(2026, 1, 1),
          status: const Value('failed'),
        ),
      );
      await queue.retryFailed('a');
      final row = (await rows()).single;
      expect(row.status, 'failed');
      expect(row.lastError, 'otra vez');
    });
  });

  group('watchQueue', () {
    test(
      'refleja la cola del AppDatabase (pending + failed, no borradas)',
      () async {
        build(_FakeExecution([_connectionError(), _httpError(400)]));
        await submitScan(key: 'pend'); // queda pending (sin red)
        await submitScan(key: 'fail'); // queda failed (4xx)
        final snapshot = await queue.watchQueue().first;
        final byId = {for (final r in snapshot) r.id: r.status};
        expect(byId, {'pend': 'pending', 'fail': 'failed'});
      },
    );
  });
}
