import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/carrier.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';

import '../../carrier_fixtures.dart';
import '../../carrier_test_harness.dart';

// Controllers del transportista: la elección en memoria y los FutureProviders de
// lectura (lista de transportistas, liquidaciones y detalle).

ProviderContainer _container(FakeCarrierRepository repo) {
  final container = ProviderContainer(
    // Sin reintentos: el retry por defecto de Riverpod vuelve a "loading" y
    // compite con el autoDispose, enmascarando el error con un StateError.
    retry: (_, _) => null,
    overrides: [carrierRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SelectedCarrierNotifier', () {
    test('arranca en null, select guarda y clear limpia', () {
      final container = _container(FakeCarrierRepository());
      expect(container.read(selectedCarrierProvider), isNull);

      final c = carrier();
      container.read(selectedCarrierProvider.notifier).select(c);
      expect(container.read(selectedCarrierProvider), same(c));

      container.read(selectedCarrierProvider.notifier).clear();
      expect(container.read(selectedCarrierProvider), isNull);
    });
  });

  group('carriersListProvider', () {
    test('con datos devuelve los transportistas activos', () async {
      final container = _container(
        FakeCarrierRepository(onListCarriers: () async => [carrier()]),
      );
      expect(await container.read(carriersListProvider.future), hasLength(1));
    });

    test('sin datos devuelve lista vacía', () async {
      final container = _container(
        FakeCarrierRepository(onListCarriers: () async => <Carrier>[]),
      );
      expect(await container.read(carriersListProvider.future), isEmpty);
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeCarrierRepository(
          onListCarriers: () async =>
              throw const ApiException(status: 500, title: 'Boom'),
        ),
      );
      await expectLater(
        container.read(carriersListProvider.future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('carrierSettlementsProvider', () {
    test('devuelve las liquidaciones del transportista indicado', () async {
      final container = _container(
        FakeCarrierRepository(
          onListSettlements: (carrierId) async => [
            settlement(carrierId: carrierId),
          ],
        ),
      );
      final list = await container.read(
        carrierSettlementsProvider('c1').future,
      );
      expect(list.single.carrierId, 'c1');
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeCarrierRepository(
          onListSettlements: (_) async =>
              throw const ApiException(status: 503, title: 'Caído'),
        ),
      );
      await expectLater(
        container.read(carrierSettlementsProvider('c1').future),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('carrierSettlementProvider', () {
    test('devuelve el detalle de una liquidación', () async {
      final container = _container(
        FakeCarrierRepository(
          onGetSettlement: (id) async => settlement(id: id),
        ),
      );
      final s = await container.read(carrierSettlementProvider('s9').future);
      expect(s.id, 's9');
    });

    test('propaga el error de API', () async {
      final container = _container(
        FakeCarrierRepository(
          onGetSettlement: (_) async =>
              throw const ApiException(status: 404, title: 'No existe'),
        ),
      );
      await expectLater(
        container.read(carrierSettlementProvider('s1').future),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
