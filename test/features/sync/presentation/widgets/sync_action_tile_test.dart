import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/features/sync/presentation/widgets/sync_action_tile.dart';

// Fila de una acción de la cola: pendiente (hora, sin botón) o fallida (motivo y
// botón de reintento, que llama a retryFailed con el id).

class _FakeOfflineQueue implements OfflineQueue {
  final List<String> retried = [];

  @override
  Future<void> retryFailed(String id) async => retried.add(id);

  @override
  Future<void> drain() async {}

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<SubmitOutcome> submit({
    required String kind,
    required Map<String, Object?> payload,
    required String label,
    DateTime? occurredAt,
    String? idempotencyKey,
  }) async => SubmitOutcome.sent;

  @override
  Stream<List<OutboxAction>> watchQueue() =>
      const Stream<List<OutboxAction>>.empty();
}

OutboxAction _action({
  required String status,
  String? label,
  String? lastError,
}) => OutboxAction(
  id: 'id-1',
  kind: 'recordLoadScan',
  payload: '{}',
  occurredAt: DateTime(2026, 3, 5, 14, 30),
  status: status,
  attempts: status == 'failed' ? 1 : 0,
  lastError: lastError,
  createdAt: DateTime(2026, 3, 5, 14, 30),
  label: label,
);

Future<void> _pump(
  WidgetTester tester,
  OutboxAction action,
  _FakeOfflineQueue offline,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [offlineQueueProvider.overrideWithValue(offline)],
      child: MaterialApp(
        home: Scaffold(body: SyncActionTile(action: action)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pendiente: muestra la etiqueta, la hora y la pastilla', (
    tester,
  ) async {
    await _pump(
      tester,
      _action(status: 'pending', label: 'Carga · pedido 123'),
      _FakeOfflineQueue(),
    );

    expect(find.text('Carga · pedido 123'), findsOneWidget);
    expect(find.textContaining('En cola · '), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('pendiente sin label: cae al kind', (tester) async {
    await _pump(tester, _action(status: 'pending'), _FakeOfflineQueue());

    expect(find.text('recordLoadScan'), findsOneWidget);
  });

  testWidgets('fallida: muestra el motivo y el botón de reintento', (
    tester,
  ) async {
    await _pump(
      tester,
      _action(
        status: 'failed',
        label: 'Carga · pedido 123',
        lastError: 'Rechazada por el servidor',
      ),
      _FakeOfflineQueue(),
    );

    expect(find.text('Rechazada por el servidor'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
  });

  testWidgets('fallida sin motivo: muestra "Rechazada"', (tester) async {
    await _pump(tester, _action(status: 'failed'), _FakeOfflineQueue());

    expect(find.text('Rechazada'), findsOneWidget);
  });

  testWidgets('tocar "Reintentar" llama a retryFailed con el id', (
    tester,
  ) async {
    final offline = _FakeOfflineQueue();
    await _pump(tester, _action(status: 'failed'), offline);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(offline.retried, ['id-1']);
  });
}
