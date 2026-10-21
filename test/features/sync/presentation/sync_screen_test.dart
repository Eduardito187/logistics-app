import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/sync/presentation/sync_screen.dart';
import 'package:logistics_app/features/sync/presentation/widgets/sync_action_tile.dart';

// Pantalla de sincronización: estados de la cola offline (cargando, error,
// vacía, con pendientes) y banner de conectividad. Se override el stream de la
// cola, la conectividad y el servicio de cola (para la acción "Reintentar
// ahora") con falsos; nada de Drift real.

class _FakeConnectivity extends ConnectivityNotifier {
  _FakeConnectivity({required this.online});
  final bool online;
  @override
  Future<bool> build() async => online;
}

class _FakeOfflineQueue implements OfflineQueue {
  bool drained = false;
  final List<String> retried = [];

  @override
  Future<void> drain() async => drained = true;

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<void> retryFailed(String id) async => retried.add(id);

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

OutboxAction _pending(String id, {String? label}) => OutboxAction(
  id: id,
  kind: 'recordLoadScan',
  payload: '{}',
  occurredAt: DateTime(2026, 3, 5, 14, 30),
  status: 'pending',
  attempts: 0,
  createdAt: DateTime(2026, 3, 5, 14, 30),
  label: label,
);

OutboxAction _failed(String id, {String? error}) => OutboxAction(
  id: id,
  kind: 'recordLoadScan',
  payload: '{}',
  occurredAt: DateTime(2026, 3, 5, 14, 30),
  status: 'failed',
  attempts: 1,
  lastError: error,
  createdAt: DateTime(2026, 3, 5, 14, 30),
  label: 'Carga · pedido 123',
);

Future<void> _pump(
  WidgetTester tester, {
  required Stream<List<OutboxAction>> queue,
  bool online = true,
  _FakeOfflineQueue? offline,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        syncQueueProvider.overrideWith((ref) => queue),
        connectivityProvider.overrideWith(
          () => _FakeConnectivity(online: online),
        ),
        offlineQueueProvider.overrideWithValue(offline ?? _FakeOfflineQueue()),
      ],
      child: const MaterialApp(home: SyncScreen()),
    ),
  );
}

void main() {
  testWidgets('cola vacía: muestra el estado "todo sincronizado"', (
    tester,
  ) async {
    await _pump(tester, queue: Stream.value(const []));
    await tester.pumpAndSettle();

    expect(find.text('Todo sincronizado'), findsOneWidget);
    expect(
      find.text('No hay escaneos ni registros pendientes de subir.'),
      findsOneWidget,
    );
    expect(find.byType(SyncActionTile), findsNothing);
  });

  testWidgets('con pendientes: lista los tiles y el banner con señal', (
    tester,
  ) async {
    await _pump(
      tester,
      online: true,
      queue: Stream.value([_pending('a', label: 'Carga'), _failed('b')]),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SyncActionTile), findsNWidgets(2));
    expect(
      find.text('Con señal. Las acciones se suben automáticamente.'),
      findsOneWidget,
    );
  });

  testWidgets('sin señal: el banner avisa que se subirá al reconectar', (
    tester,
  ) async {
    await _pump(
      tester,
      online: false,
      queue: Stream.value([_pending('a', label: 'Carga')]),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sin señal. Se subirán al recuperar conexión.'),
      findsOneWidget,
    );
  });

  testWidgets('mientras carga la cola: muestra el indicador', (tester) async {
    // Stream que nunca emite → estado de carga.
    await _pump(
      tester,
      queue: Stream<List<OutboxAction>>.fromFuture(
        Completer<List<OutboxAction>>().future,
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error al leer la cola: muestra el estado de error', (
    tester,
  ) async {
    await _pump(
      tester,
      queue: Stream<List<OutboxAction>>.error(Exception('db rota')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo leer la cola'), findsOneWidget);
  });

  testWidgets('"Reintentar ahora" drena la cola', (tester) async {
    final offline = _FakeOfflineQueue();
    await _pump(
      tester,
      queue: Stream.value([_pending('a', label: 'Carga')]),
      offline: offline,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Reintentar ahora'));
    await tester.pump();

    expect(offline.drained, isTrue);
  });
}
