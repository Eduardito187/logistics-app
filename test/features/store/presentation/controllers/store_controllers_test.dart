import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/store/data/repositories/store_repository_impl.dart';
import 'package:logistics_app/features/store/presentation/controllers/locally_received_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/selected_store_node_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/shelf_locations_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_controllers.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';

import '../../store_fixtures.dart';
import '../../store_test_harness.dart';

// Controllers del feature Tienda: los tres Notifier en memoria y los
// FutureProviders de lectura (nodos, envíos, recepción, productos). Las
// lecturas se prueban cableando un repositorio falso vía `storeRepositoryProvider`.

ProviderContainer _container(FakeStoreRepository repo) {
  final container = ProviderContainer(
    // Sin reintentos: el retry por defecto de Riverpod vuelve a "loading" y
    // compite con el autoDispose, enmascarando el error con un StateError.
    retry: (_, _) => null,
    overrides: [storeRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('selectedStoreNodeProvider (tienda fija del usuario)', () {
    test('sin sesión no hay tienda', () {
      final container = _container(FakeStoreRepository());
      expect(container.read(selectedStoreNodeProvider), isNull);
    });

    test('es la tienda asignada en la sesión (/me), sin selector', () {
      final container = _container(FakeStoreRepository());
      final session = container.read(sessionProvider.notifier)
        ..devSignIn(UserRole.store);
      expect(container.read(selectedStoreNodeProvider), isNull);

      final node = storeNode();
      session.applyProfile(abilities: const [], storeNode: node);
      expect(container.read(selectedStoreNodeProvider), same(node));
    });
  });

  group('LocallyReceivedNotifier', () {
    test('acumula ids de producto por envío y los lee con forShipment', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier);

      expect(notifier.forShipment('ship-1'), isEmpty);
      notifier.add('ship-1', 'unit-1');
      notifier.add('ship-1', 'unit-2');
      notifier.add('ship-2', 'unit-9');

      expect(notifier.forShipment('ship-1'), {'unit-1', 'unit-2'});
      expect(notifier.forShipment('ship-2'), {'unit-9'});
    });

    test('agregar el mismo producto dos veces no lo duplica (Set)', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier);
      notifier
        ..add('ship-1', 'unit-1')
        ..add('ship-1', 'unit-1');
      expect(notifier.forShipment('ship-1'), {'unit-1'});
    });

    test('cada add emite un mapa nuevo (inmutabilidad)', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier);
      final first = container.read(locallyReceivedProvider);
      notifier.add('ship-1', 'unit-1');
      final second = container.read(locallyReceivedProvider);
      expect(identical(first, second), isFalse);
    });

    test('clear olvida el envío conciliado', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier)
        ..add('ship-1', 'unit-1')
        ..add('ship-2', 'unit-2');
      notifier.clear('ship-1');
      expect(container.read(locallyReceivedProvider).keys, ['ship-2']);
    });

    test('recuerda a lo sumo maxShipments envíos (descarta el más viejo)', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier);
      const max = LocallyReceivedNotifier.maxShipments;
      for (var i = 0; i <= max; i++) {
        notifier.add('ship-$i', 'unit-$i');
      }
      final state = container.read(locallyReceivedProvider);
      expect(state, hasLength(max));
      expect(state.containsKey('ship-0'), isFalse);
      expect(state.containsKey('ship-$max'), isTrue);
    });
  });

  group('ShelfLocationsNotifier', () {
    test('guarda y sobrescribe la ubicación por producto', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(shelfLocationsProvider.notifier);

      notifier.setLocation('unit-1', 'Pasillo 3 · B2');
      expect(
        container.read(shelfLocationsProvider)['unit-1'],
        'Pasillo 3 · B2',
      );

      notifier.setLocation('unit-1', 'Pasillo 4 · C1');
      expect(
        container.read(shelfLocationsProvider)['unit-1'],
        'Pasillo 4 · C1',
      );
    });

    test('recuerda a lo sumo maxEntries ubicaciones', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(shelfLocationsProvider.notifier);
      const max = ShelfLocationsNotifier.maxEntries;
      for (var i = 0; i <= max; i++) {
        notifier.setLocation('unit-$i', 'P$i');
      }
      final state = container.read(shelfLocationsProvider);
      expect(state, hasLength(max));
      expect(state.containsKey('unit-0'), isFalse);
    });
  });

  group('storeNodesProvider', () {
    test('con datos devuelve la lista de nodos', () async {
      final container = _container(
        FakeStoreRepository(onListNodes: () async => [storeNode()]),
      );
      final nodes = await container.read(storeNodesProvider.future);
      expect(nodes, hasLength(1));
      expect(nodes.first.name, 'Tienda Centro');
    });

    test('sin datos devuelve lista vacía', () async {
      final container = _container(
        FakeStoreRepository(onListNodes: () async => <Node>[]),
      );
      expect(await container.read(storeNodesProvider.future), isEmpty);
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeStoreRepository(
          onListNodes: () async =>
              throw const ApiException(status: 500, title: 'Boom'),
        ),
      );
      await expectLater(
        container.read(storeNodesProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('storeShipmentsPagedProvider', () {
    test('con datos devuelve los envíos', () async {
      final container = _container(
        FakeStoreRepository(onListShipments: () async => [shipment()]),
      );
      final state = await container.read(storeShipmentsPagedProvider.future);
      expect(state.shipments, hasLength(1));
      expect(state.hasMore, isFalse);
    });

    test('pide la primera página con el tamaño de página de la app', () async {
      final repo = FakeStoreRepository(onListShipments: () async => []);
      final container = _container(repo);

      await container.read(storeShipmentsPagedProvider.future);

      expect(repo.shipmentPageRequests, [
        (page: 1, perPage: kStoreShipmentsPageSize),
      ]);
    });

    test('la vista de solo lectura expone la lista acumulada', () async {
      final container = _container(
        FakeStoreRepository(onListShipments: () async => [shipment()]),
      );
      await container.read(storeShipmentsPagedProvider.future);
      expect(container.read(storeShipmentsProvider).value, hasLength(1));
    });

    test(
      'pide al servidor solo los envíos de la tienda de la sesión',
      () async {
        final repo = FakeStoreRepository();
        final container = ProviderContainer(
          retry: (_, _) => null,
          overrides: [
            storeRepositoryProvider.overrideWithValue(repo),
            selectedStoreNodeProvider.overrideWithValue(
              storeNode(id: 'mi-nodo'),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(storeShipmentsPagedProvider.future);

        expect(repo.listShipmentsNodeIds, ['mi-nodo']);
      },
    );

    test('Recepción y Recojo comparten la lista: un solo GET', () async {
      final repo = FakeStoreRepository();
      final container = _container(repo);

      final a = container.listen(storeShipmentsPagedProvider, (_, _) {});
      final b = container.listen(storeShipmentsPagedProvider, (_, _) {});
      await container.read(storeShipmentsPagedProvider.future);
      a.close();
      b.close();
      // Volver a la pantalla dentro del plazo de caché: sin otro GET.
      await Future<void>.delayed(Duration.zero);
      await container.read(storeShipmentsPagedProvider.future);

      expect(repo.listShipmentsNodeIds, hasLength(1));
    });
  });

  group('caché de listas (cacheFor)', () {
    testWidgets('envíos: vuelve sin GET dentro de 60 s y re-pide después', (
      tester,
    ) async {
      final repo = FakeStoreRepository();
      // Se libera al final del cuerpo: los timers de caché no quedan vivos.
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [storeRepositoryProvider.overrideWithValue(repo)],
      );

      final sub = container.listen(storeShipmentsPagedProvider, (_, _) {});
      await tester.pump();
      sub.close();
      await tester.pump(const Duration(seconds: 59));
      container.listen(storeShipmentsPagedProvider, (_, _) {}).close();
      await tester.pump();
      expect(repo.listShipmentsNodeIds, hasLength(1));

      await tester.pump(const Duration(seconds: 61));
      container.listen(storeShipmentsPagedProvider, (_, _) {});
      await tester.pump();
      expect(repo.listShipmentsNodeIds, hasLength(2));
      container.dispose();
    });

    testWidgets('nodos: caché larga (10 min)', (tester) async {
      var calls = 0;
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          storeRepositoryProvider.overrideWithValue(
            FakeStoreRepository(
              onListNodes: () async {
                calls++;
                return <Node>[];
              },
            ),
          ),
        ],
      );

      container.listen(storeNodesProvider, (_, _) {}).close();
      await tester.pump(const Duration(minutes: 9));
      container.listen(storeNodesProvider, (_, _) {}).close();
      await tester.pump();
      expect(calls, 1);

      await tester.pump(const Duration(minutes: 11));
      container.listen(storeNodesProvider, (_, _) {});
      await tester.pump();
      expect(calls, 2);
      container.dispose();
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeStoreRepository(
          onListShipments: () async =>
              throw const ApiException(status: 503, title: 'Caído'),
        ),
      );
      await expectLater(
        container.read(storeShipmentsPagedProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('nodeReceptionProvider', () {
    test('devuelve la vista de recepción para la clave envío+nodo', () async {
      final container = _container(
        FakeStoreRepository(
          onGetNodeReception: (shipmentId, nodeId) async =>
              reception(shipmentId: shipmentId, destinationNodeId: nodeId),
        ),
      );
      final view = await container.read(
        nodeReceptionProvider((
          shipmentId: 'ship-1',
          nodeId: 'node-store',
        )).future,
      );
      expect(view, isA<NodeReceptionView>());
      expect(view!.destinationNodeId, 'node-store');
    });

    test('null cuando aún no se abrió (404 traducido a null)', () async {
      final container = _container(
        FakeStoreRepository(onGetNodeReception: (_, _) async => null),
      );
      final view = await container.read(
        nodeReceptionProvider((
          shipmentId: 'ship-1',
          nodeId: 'node-store',
        )).future,
      );
      expect(view, isNull);
    });
  });

  group('shipmentUnitsProvider', () {
    test('devuelve los productos esperados del envío', () async {
      final container = _container(
        FakeStoreRepository(
          onGetShipmentUnits: (shipmentId) async => [
            unit(unitId: 'u1', shipmentId: shipmentId),
            unit(unitId: 'u2', shipmentId: shipmentId),
          ],
        ),
      );
      final units = await container.read(
        shipmentUnitsProvider('ship-1').future,
      );
      expect(units.map((u) => u.unitId), ['u1', 'u2']);
    });

    test('sin productos devuelve lista vacía', () async {
      final container = _container(
        FakeStoreRepository(onGetShipmentUnits: (_) async => <UnitTracking>[]),
      );
      expect(await container.read(shipmentUnitsProvider('x').future), isEmpty);
    });
  });

  group('deliveredUnitIdsProvider', () {
    test('devuelve los productos con prueba de entrega del servidor', () async {
      final repo = FakeStoreRepository(
        onGetDeliveryState: (shipmentId) async =>
            delivery(shipmentId: shipmentId, podUnitIds: ['u1', 'u2']),
      );
      final container = _container(repo);

      expect(await container.read(deliveredUnitIdsProvider('ship-1').future), {
        'u1',
        'u2',
      });
    });

    test('ignora los escaneos que no son entrega (carga/descarga)', () async {
      final container = _container(
        FakeStoreRepository(
          onGetDeliveryState: (_) async =>
              delivery(podUnitIds: ['u1'], otherUnitIds: ['u2', 'u3']),
        ),
      );

      expect(await container.read(deliveredUnitIdsProvider('ship-1').future), {
        'u1',
      });
    });

    test('sin entregas confirmadas devuelve conjunto vacío', () async {
      final container = _container(
        FakeStoreRepository(onGetDeliveryState: (_) async => delivery()),
      );
      expect(
        await container.read(deliveredUnitIdsProvider('ship-1').future),
        isEmpty,
      );
    });

    // Offline-first (regla 4): la consulta es solo un refuerzo contra la doble
    // entrega; si falla, el retiro no se traba con un error.
    test('error de API: conjunto vacío, no propaga', () async {
      final container = _container(
        FakeStoreRepository(
          onGetDeliveryState: (_) async =>
              throw const ApiException(status: 503, title: 'Caído'),
        ),
      );
      expect(
        await container.read(deliveredUnitIdsProvider('ship-1').future),
        isEmpty,
      );
    });

    test('sin red (fallo de transporte): conjunto vacío', () async {
      final container = _container(
        FakeStoreRepository(
          onGetDeliveryState: (_) async =>
              throw Exception('SocketException: sin red'),
        ),
      );
      expect(
        await container.read(deliveredUnitIdsProvider('ship-1').future),
        isEmpty,
      );
    });
  });
}
