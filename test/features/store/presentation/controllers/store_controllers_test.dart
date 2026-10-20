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

import '../../store_fixtures.dart';
import '../../store_test_harness.dart';

// Controllers del feature Tienda: los tres Notifier en memoria y los
// FutureProviders de lectura (nodos, envíos, recepción, bultos). Las lecturas se
// prueban cableando un repositorio falso vía `storeRepositoryProvider`.

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
    test('acumula ids de bulto por envío y los lee con forShipment', () {
      final container = _container(FakeStoreRepository());
      final notifier = container.read(locallyReceivedProvider.notifier);

      expect(notifier.forShipment('ship-1'), isEmpty);
      notifier.add('ship-1', 'unit-1');
      notifier.add('ship-1', 'unit-2');
      notifier.add('ship-2', 'unit-9');

      expect(notifier.forShipment('ship-1'), {'unit-1', 'unit-2'});
      expect(notifier.forShipment('ship-2'), {'unit-9'});
    });

    test('agregar el mismo bulto dos veces no lo duplica (Set)', () {
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
  });

  group('ShelfLocationsNotifier', () {
    test('guarda y sobrescribe la ubicación por bulto', () {
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

  group('storeShipmentsProvider', () {
    test('con datos devuelve los envíos', () async {
      final container = _container(
        FakeStoreRepository(onListShipments: () async => [shipment()]),
      );
      expect(await container.read(storeShipmentsProvider.future), hasLength(1));
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeStoreRepository(
          onListShipments: () async =>
              throw const ApiException(status: 503, title: 'Caído'),
        ),
      );
      await expectLater(
        container.read(storeShipmentsProvider.future),
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
    test('devuelve los bultos esperados del envío', () async {
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

    test('sin bultos devuelve lista vacía', () async {
      final container = _container(
        FakeStoreRepository(onGetShipmentUnits: (_) async => <UnitTracking>[]),
      );
      expect(await container.read(shipmentUnitsProvider('x').future), isEmpty);
    });
  });
}
