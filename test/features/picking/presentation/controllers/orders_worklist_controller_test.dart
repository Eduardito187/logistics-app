import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/shipment_status.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/picking/data/repositories/picking_repository_impl.dart';
import 'package:logistics_app/features/picking/presentation/controllers/orders_worklist_controller.dart';

import '../../picking_test_harness.dart';

// Cableado del provider de la worklist: resuelve el caso de uso (y su filtro)
// sobre el repositorio falso. Se override el repositorio y se lee el
// FutureProvider a través de un ProviderContainer.

ProviderContainer _containerWith(FakePickingRepository repo) {
  final container = ProviderContainer(
    // Riverpod reintenta por defecto los providers que fallan, dejándolos en
    // AsyncLoading(error) para siempre; en los tests queremos que el error se
    // asiente para poder esperarlo desde `.future`.
    retry: (_, _) => null,
    overrides: [pickingRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  // Mantiene vivo el provider autoDispose mientras se espera su future.
  container.listen(ordersToPrepareProvider, (_, _) {});
  return container;
}

void main() {
  test('ordersToPrepareProvider entrega sólo received y planned', () async {
    final container = _containerWith(
      FakePickingRepository(
        onListShipments: () async => [
          buildShipment(externalId: 'A', status: ShipmentStatus.received),
          buildShipment(externalId: 'B', status: ShipmentStatus.inExecution),
          buildShipment(externalId: 'C', status: ShipmentStatus.planned),
        ],
      ),
    );

    final orders = await container.read(ordersToPrepareProvider.future);

    expect(orders.map((s) => s.externalId), ['A', 'C']);
  });

  test('sin pedidos vigentes entrega lista vacía', () async {
    final container = _containerWith(
      FakePickingRepository(
        onListShipments: () async => [
          buildShipment(externalId: 'D', status: ShipmentStatus.delivered),
        ],
      ),
    );

    expect(await container.read(ordersToPrepareProvider.future), isEmpty);
  });

  test('propaga el error del backend como AsyncError', () async {
    final container = _containerWith(
      FakePickingRepository(
        onListShipments: () async =>
            throw const ApiException(status: 503, title: 'Caído'),
      ),
    );

    await expectLater(
      container.read(ordersToPrepareProvider.future),
      throwsA(isA<ApiException>()),
    );
  });
}
