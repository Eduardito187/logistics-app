import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/picking/domain/usecases/list_orders_to_prepare.dart';

import '../picking_test_harness.dart';

// Caso de uso Query: pedidos "por preparar/cargar". El filtro por estado vive
// en el caso de uso (el endpoint sólo admite un estado por consulta), así que se
// verifica con el repositorio falso devolviendo una colección mixta.

void main() {
  group('ListOrdersToPrepare', () {
    test('toPrepareStatuses es exactamente {received, planned}', () {
      expect(ListOrdersToPrepare.toPrepareStatuses, {
        ShipmentStatus.received,
        ShipmentStatus.planned,
      });
    });

    test('conserva sólo received y planned; excluye el resto', () async {
      final repo = FakePickingRepository(
        onListShipments: () async => [
          buildShipment(externalId: 'A', status: ShipmentStatus.received),
          buildShipment(externalId: 'B', status: ShipmentStatus.planned),
          buildShipment(externalId: 'C', status: ShipmentStatus.inExecution),
          buildShipment(externalId: 'D', status: ShipmentStatus.delivered),
          buildShipment(externalId: 'E', status: ShipmentStatus.failed),
          buildShipment(externalId: 'F', status: ShipmentStatus.cancelled),
          buildShipment(externalId: 'G', status: ShipmentStatus.$unknown),
        ],
      );

      final result = await ListOrdersToPrepare(repo).call();

      // Primero lo planificado (ya tiene ruta), después lo recibido.
      expect(result.map((s) => s.externalId), ['B', 'A']);
    });

    test('filtra en el servidor: un pedido por estado, en paralelo', () async {
      final repo = FakePickingRepository();

      await ListOrdersToPrepare(repo).call();

      expect(repo.listShipmentsStatuses, [
        ShipmentStatus.planned,
        ShipmentStatus.received,
      ]);
    });

    test('no duplica un pedido que llega en dos consultas', () async {
      final repo = FakePickingRepository(
        onListShipments: () async => [
          buildShipment(externalId: 'A', status: ShipmentStatus.received),
        ],
      );

      final result = await ListOrdersToPrepare(repo).call();

      expect(result.map((s) => s.externalId), ['A']);
    });

    test('dentro de cada estado preserva el orden del servidor', () async {
      final repo = FakePickingRepository(
        onListShipments: () async => [
          buildShipment(
            externalId: 'planned-1',
            status: ShipmentStatus.planned,
          ),
          buildShipment(externalId: 'done', status: ShipmentStatus.delivered),
          buildShipment(
            externalId: 'received-1',
            status: ShipmentStatus.received,
          ),
          buildShipment(
            externalId: 'planned-2',
            status: ShipmentStatus.planned,
          ),
        ],
      );

      final result = await ListOrdersToPrepare(repo).call();

      expect(result.map((s) => s.externalId), [
        'planned-1',
        'planned-2',
        'received-1',
      ]);
    });

    test('lista vacía del backend devuelve lista vacía', () async {
      final repo = FakePickingRepository(onListShipments: () async => []);

      expect(await ListOrdersToPrepare(repo).call(), isEmpty);
    });

    test('si todo está en estados terminales devuelve vacío', () async {
      final repo = FakePickingRepository(
        onListShipments: () async => [
          buildShipment(externalId: 'X', status: ShipmentStatus.delivered),
          buildShipment(externalId: 'Y', status: ShipmentStatus.cancelled),
        ],
      );

      expect(await ListOrdersToPrepare(repo).call(), isEmpty);
    });

    test('propaga la ApiException del repositorio', () async {
      final repo = FakePickingRepository(
        onListShipments: () async =>
            throw const ApiException(status: 500, title: 'Boom'),
      );

      expect(
        () => ListOrdersToPrepare(repo).call(),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
