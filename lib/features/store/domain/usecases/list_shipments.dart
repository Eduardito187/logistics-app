import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/store_repository_impl.dart';
import '../entities/shipment_page.dart';
import '../repositories/store_repository.dart';
import '../repositories/store_shipments_pager.dart';

/// Query: una página de envíos visibles para recepción / entrega en mostrador.
///
/// [destinationNodeId] es la tienda del usuario: el filtro se aplica en el
/// servidor para no bajar envíos de otras tiendas.
class ListShipments {
  const ListShipments(this._repo);

  final StoreRepository _repo;

  Future<ShipmentPage> call({
    String? destinationNodeId,
    required int page,
    required int perPage,
  }) async {
    // `StoreShipmentsPager` no es subtipo de `StoreRepository` (contrato
    // aparte, ver su doc), así que no hay promoción: se castea a mano.
    final repo = _repo;
    if (repo is StoreShipmentsPager) {
      return (repo as StoreShipmentsPager).listShipmentsPage(
        destinationNodeId: destinationNodeId,
        page: page,
        perPage: perPage,
      );
    }
    // Repositorio que solo implementa el contrato base (dobles de prueba):
    // una sola página, como antes de paginar.
    if (page > 1) return ShipmentPage.empty;
    final shipments = await repo.listShipments(
      destinationNodeId: destinationNodeId,
    );
    return ShipmentPage(shipments: shipments, hasMore: false);
  }
}

final listShipmentsProvider = Provider<ListShipments>(
  (ref) => ListShipments(ref.watch(storeRepositoryProvider)),
);
