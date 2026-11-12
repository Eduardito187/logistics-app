import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/domain/entities/shipment_page.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';

import '../../store_fixtures.dart';
import '../../store_test_harness.dart';

// Scroll infinito de la lista de envíos de tienda: antes se pedía sin
// `page`/`per_page` y los envíos después del 50 se perdían en silencio.

ProviderContainer _container(FakeStoreRepository repo) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      storeRepositoryProvider.overrideWithValue(repo),
      selectedStoreNodeProvider.overrideWithValue(storeNode(id: 'mi-nodo')),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Repositorio con [total] envíos repartidos en páginas de [perPage].
FakeStoreRepository _paged(int total) => FakeStoreRepository(
  onListShipmentsPage: (page, perPage) async {
    final start = (page - 1) * perPage;
    final end = start + perPage;
    return ShipmentPage(
      shipments: [
        for (var i = start; i < end && i < total; i++)
          shipment(id: 'ship-$i', customerName: 'Cliente $i'),
      ],
      hasMore: end < total,
    );
  },
);

void main() {
  test(
    'la primera página trae hasta el tamaño de página y marca que hay más',
    () async {
      final repo = _paged(120);
      final container = _container(repo);

      final state = await container.read(storeShipmentsPagedProvider.future);

      expect(state.shipments, hasLength(kStoreShipmentsPageSize));
      expect(state.hasMore, isTrue);
      expect(state.loadingMore, isFalse);
      expect(repo.shipmentPageRequests, [
        (page: 1, perPage: kStoreShipmentsPageSize),
      ]);
    },
  );

  test('loadMore agrega la página siguiente al final de la lista', () async {
    final repo = _paged(120);
    final container = _container(repo);
    await container.read(storeShipmentsPagedProvider.future);

    await container.read(storeShipmentsPagedProvider.notifier).loadMore();

    final state = container.read(storeShipmentsPagedProvider).value!;
    expect(state.shipments, hasLength(kStoreShipmentsPageSize * 2));
    expect(state.shipments.first.id, 'ship-0');
    expect(state.shipments.last.id, 'ship-99');
    expect(state.hasMore, isTrue);
    expect(state.loadingMore, isFalse);
    expect(repo.shipmentPageRequests.map((r) => r.page), [1, 2]);
  });

  test('al traer la última página deja de pedir más', () async {
    final repo = _paged(60);
    final container = _container(repo);
    await container.read(storeShipmentsPagedProvider.future);
    final notifier = container.read(storeShipmentsPagedProvider.notifier);

    await notifier.loadMore();
    expect(container.read(storeShipmentsPagedProvider).value!.hasMore, isFalse);

    // Sin más páginas, pedir de nuevo (scroll al final) no genera otro GET.
    await notifier.loadMore();
    expect(repo.shipmentPageRequests, hasLength(2));
  });

  test('no se repiten envíos si la bandeja se movió', () async {
    final repo = FakeStoreRepository(
      onListShipmentsPage: (page, perPage) async => ShipmentPage(
        shipments: [
          shipment(id: 'ship-1'),
          shipment(id: 'ship-2'),
        ],
        hasMore: page < 2,
      ),
    );
    final container = _container(repo);
    await container.read(storeShipmentsPagedProvider.future);

    await container.read(storeShipmentsPagedProvider.notifier).loadMore();

    final state = container.read(storeShipmentsPagedProvider).value!;
    expect(state.shipments.map((s) => s.id), ['ship-1', 'ship-2']);
  });

  test('si falla una página conserva lo visible y reintenta', () async {
    var calls = 0;
    final repo = FakeStoreRepository(
      onListShipmentsPage: (page, perPage) async {
        calls++;
        if (page == 1) {
          return ShipmentPage(shipments: [shipment()], hasMore: true);
        }
        if (calls == 2) {
          throw const ApiException(status: 503, title: 'Caído');
        }
        return ShipmentPage(
          shipments: [shipment(id: 'ship-2')],
          hasMore: false,
        );
      },
    );
    final container = _container(repo);
    await container.read(storeShipmentsPagedProvider.future);
    final notifier = container.read(storeShipmentsPagedProvider.notifier);

    await notifier.loadMore();

    var state = container.read(storeShipmentsPagedProvider).value!;
    expect(state.shipments, hasLength(1), reason: 'no se pierde lo cargado');
    expect(state.moreFailed, isTrue);
    expect(state.hasMore, isTrue);
    expect(state.loadingMore, isFalse);

    // El reintento del pie vuelve a pedir la MISMA página.
    await notifier.loadMore();
    state = container.read(storeShipmentsPagedProvider).value!;
    expect(repo.shipmentPageRequests.map((r) => r.page), [1, 2, 2]);
    expect(state.shipments.map((s) => s.id), ['ship-1', 'ship-2']);
    expect(state.moreFailed, isFalse);
  });

  test('refrescar descarta el acumulado y vuelve a la página 1', () async {
    final repo = _paged(120);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        storeRepositoryProvider.overrideWithValue(repo),
        selectedStoreNodeProvider.overrideWithValue(storeNode(id: 'nodo-a')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(storeShipmentsPagedProvider.future);
    await container.read(storeShipmentsPagedProvider.notifier).loadMore();
    expect(repo.shipmentPageRequests.map((r) => r.page), [1, 2]);

    // Refrescar (pull-to-refresh) descarta el acumulado.
    container.invalidate(storeShipmentsPagedProvider);
    final state = await container.read(storeShipmentsPagedProvider.future);

    expect(state.shipments, hasLength(kStoreShipmentsPageSize));
    expect(repo.shipmentPageRequests.map((r) => r.page), [1, 2, 1]);
  });

  test('sin envíos la lista queda vacía y sin más páginas', () async {
    final container = _container(
      FakeStoreRepository(onListShipments: () async => <Shipment>[]),
    );

    final state = await container.read(storeShipmentsPagedProvider.future);

    expect(state.shipments, isEmpty);
    expect(state.hasMore, isFalse);
  });
}
