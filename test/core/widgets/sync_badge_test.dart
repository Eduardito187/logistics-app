import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/widgets/sync_badge.dart';

// Indicador de sincronización de la AppBar. Combina conectividad y cola local:
//  - sin red: cloud_off (cuenta de pendientes o "Sin red")
//  - con red + fallidas: error_outline (cuenta de fallidas)
//  - con red + pendientes: sync (cuenta)
//  - con red y todo al día: cloud_done (sin texto)

class _FakeConnectivity extends ConnectivityNotifier {
  _FakeConnectivity(this._online);
  final bool _online;
  @override
  Future<bool> build() async => _online;
}

OutboxAction _action(String id, String status) => OutboxAction(
  id: id,
  kind: 'ingestScan',
  payload: '{}',
  occurredAt: DateTime(2024, 1, 1),
  status: status,
  attempts: 0,
  createdAt: DateTime(2024, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required bool online,
  required List<OutboxAction> queue,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith(() => _FakeConnectivity(online)),
        syncQueueProvider.overrideWith((ref) => Stream.value(queue)),
      ],
      child: MaterialApp(
        home: Scaffold(body: SyncBadge(onTap: onTap)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('con red y todo al día: cloud_done sin texto', (tester) async {
    await _pump(tester, online: true, queue: const []);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('con red y pendientes: sync con la cuenta', (tester) async {
    await _pump(
      tester,
      online: true,
      queue: [_action('a', 'pending'), _action('b', 'pending')],
    );
    expect(find.byIcon(Icons.sync), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('con red y fallidas: error_outline con la cuenta de fallidas', (
    tester,
  ) async {
    await _pump(
      tester,
      online: true,
      queue: [_action('a', 'failed'), _action('b', 'pending')],
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // solo la fallida
  });

  testWidgets('sin red con pendientes: cloud_off con la cuenta', (
    tester,
  ) async {
    await _pump(tester, online: false, queue: [_action('a', 'pending')]);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('sin red y sin pendientes: cloud_off con "Sin red"', (
    tester,
  ) async {
    await _pump(tester, online: false, queue: const []);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.text('Sin red'), findsOneWidget);
  });

  testWidgets('onTap se dispara al tocar', (tester) async {
    var taps = 0;
    await _pump(tester, online: true, queue: const [], onTap: () => taps++);
    await tester.tap(find.byType(SyncBadge));
    await tester.pump();
    expect(taps, 1);
  });
}
