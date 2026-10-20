import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/layout/breakpoints.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/sync/presentation/sync_screen.dart';
import 'package:logistics_app/features/sync/presentation/widgets/sync_action_tile.dart';

import '../../../support/screen_sizes.dart';

// Layout de la pantalla de sincronización en los 4 tamaños con letra 1.3x y
// una cola larga (pendientes y fallidas con motivos largos). Un desborde hace
// fallar el test solo.

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

void main() {
  testOnScreens('cola larga sin señal (1.3x)', (tester, screen) async {
    final actions = [
      for (var i = 0; i < 30; i++)
        i.isEven
            ? _pending('p$i', label: 'Carga validada · pedido 2026-000$i')
            : _failed(
                'f$i',
                error:
                    'El backend rechazó la acción: el pedido ya fue entregado '
                    'por otro chofer.',
              ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncQueueProvider.overrideWith((ref) => Stream.value(actions)),
          connectivityProvider.overrideWith(
            () => _FakeConnectivity(online: false),
          ),
          offlineQueueProvider.overrideWithValue(_FakeOfflineQueue()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => withTextScale(child!),
          home: const SyncScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Sin señal. Se subirán al recuperar conexión.'),
      findsOneWidget,
    );
    // Lista perezosa: no construye las 30 filas.
    expect(find.byType(SyncActionTile).evaluate().length, lessThan(30));

    final tile = tester.getRect(find.byType(SyncActionTile).first);
    expect(
      tile.width,
      lessThanOrEqualTo(AppBreakpoints.maxContentWidth - 32 + 0.5),
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -8000));
    await tester.pumpAndSettle();
    expect(find.byType(SyncActionTile), findsWidgets);
  });
}
