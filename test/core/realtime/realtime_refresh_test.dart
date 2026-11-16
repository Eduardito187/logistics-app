import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/realtime/pusher_socket.dart';
import 'package:logistics_app/core/realtime/realtime_bus.dart';
import 'package:logistics_app/core/realtime/realtime_refresh.dart';
import 'package:logistics_app/core/widgets/paged.dart';
import 'package:logistics_app/core/widgets/paged_search_list.dart';
import 'package:logistics_app/features/supervisor/data/repositories/supervisor_repository_impl.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/supervisor_controllers.dart';

import '../../features/supervisor/support/fake_supervisor_repository.dart';

// Datos que se mantienen al día con avisos de tiempo real: el aviso es una
// señal y el provider vuelve a pedir su endpoint (una sola vez por ráfaga).

RealtimeEvent _event(String name, [Map<String, Object?> data = const {}]) =>
    (channel: 'c', name: name, data: data);

Future<void> _debounce() => Future<void>.delayed(
  kRealtimeRefreshDebounce + const Duration(milliseconds: 60),
);

void main() {
  group('refreshOnRealtime', () {
    late int builds;
    late FutureProvider<int> provider;

    setUp(() {
      builds = 0;
      provider = FutureProvider.autoDispose<int>((ref) async {
        ref.refreshOnRealtime(
          RealtimeTopic.picking,
          const {'picking.updated'},
          when: (data) => realtimeMatches(data, 'order_reference', 'SO-1'),
        );
        return ++builds;
      });
    });

    test('un aviso vuelve a pedir el dato; una ráfaga, una sola vez', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(provider, (_, _) {});
      await c.read(provider.future);
      expect(builds, 1);
      // Mientras se usa, el tema está pedido.
      final bus = c.read(realtimeBusProvider);
      expect(bus.topics, {RealtimeTopic.picking});

      bus
        ..dispatch(RealtimeTopic.picking, _event('picking.updated'))
        ..dispatch(RealtimeTopic.picking, _event('picking.updated'))
        ..dispatch(RealtimeTopic.picking, _event('picking.updated'));
      await _debounce();
      await c.read(provider.future);
      expect(builds, 2);

      // Al dejar de usarse, deja el tema.
      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(bus.topics, isEmpty);
    });

    test('ignora otros eventos y avisos de otro pedido', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(provider, (_, _) {});
      await c.read(provider.future);
      final bus = c.read(realtimeBusProvider);

      bus
        ..dispatch(RealtimeTopic.picking, _event('otra.cosa'))
        ..dispatch(
          RealtimeTopic.picking,
          _event('picking.updated', {'order_reference': 'SO-2'}),
        );
      await _debounce();
      expect(builds, 1);

      bus.dispatch(
        RealtimeTopic.picking,
        _event('picking.updated', {'order_reference': 'SO-1'}),
      );
      await _debounce();
      await c.read(provider.future);
      expect(builds, 2);
    });
  });

  test('realtimeMatches: sin el dato cuenta como cambio general', () {
    expect(realtimeMatches(const {}, 'vehicle_id', 'v1'), isTrue);
    expect(
      realtimeMatches(const {'vehicle_id': null}, 'vehicle_id', 'v1'),
      isTrue,
    );
    expect(
      realtimeMatches(const {'vehicle_id': 'v1'}, 'vehicle_id', 'v1'),
      isTrue,
    );
    expect(
      realtimeMatches(const {'vehicle_id': 'v2'}, 'vehicle_id', 'v1'),
      isFalse,
    );
    expect(
      realtimeMatches(const {'vehicle_id': 'v2'}, 'vehicle_id', null),
      isTrue,
    );
  });

  test('alertas: una alerta nueva se pide al instante', () async {
    final repo = FakeSupervisorRepository();
    final c = ProviderContainer(
      overrides: [supervisorRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    c.listen(alertsProvider, (_, _) {});
    await c.read(alertsProvider.future);
    final before = repo.listAlertsCalls;

    c
        .read(realtimeBusProvider)
        .dispatch(RealtimeTopic.operations, _event('alerts.updated'));
    await _debounce();
    await c.read(alertsProvider.future);
    expect(repo.listAlertsCalls, before + 1);
  });

  testWidgets('lista paginada: refresco silencioso, sin volver al inicio', (
    tester,
  ) async {
    var version = 1;
    final calls = <int>[];
    final key = GlobalKey<PagedSearchListState<String>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PagedSearchList<String>(
            key: key,
            emptyTitle: 'Nada',
            showSearch: false,
            fetch: (query, page) async {
              calls.add(page);
              return Paged(
                items: [for (var i = 0; i < 3; i++) 'p$page-$i v$version'],
                hasMore: page < 2,
              );
            },
            itemBuilder: (context, item) =>
                SizedBox(height: 400, child: Text(item)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Se baja hasta cargar la segunda página.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(calls, [1, 2]);

    version = 2;
    await key.currentState!.refreshSilently();
    await tester.pump();

    // Se volvieron a pedir las dos páginas ya cargadas, en su lugar.
    expect(calls, [1, 2, 1, 2]);
    expect(find.textContaining('v1'), findsNothing);
    expect(find.textContaining('v2'), findsWidgets);
    expect(find.text('p1-0 v2'), findsNothing, reason: 'no volvió al inicio');
  });
}
