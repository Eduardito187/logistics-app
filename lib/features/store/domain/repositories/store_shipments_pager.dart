import '../entities/shipment_page.dart';

/// Contrato ADICIONAL de paginación de la lista de envíos.
///
/// Va aparte de `StoreRepository` a propósito: los dobles que solo implementan
/// el contrato base (incluido el backend falso del e2e) siguen compilando y el
/// caso de uso los degrada a "una sola página" en vez de romperlos. Cuando
/// todos sepan paginar se puede fusionar en `StoreRepository`.
abstract interface class StoreShipmentsPager {
  /// Una página de envíos del nodo ([page] desde 1).
  Future<ShipmentPage> listShipmentsPage({
    String? destinationNodeId,
    required int page,
    required int perPage,
  });
}
