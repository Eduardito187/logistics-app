import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../data/repositories/picking_repository_impl.dart';
import '../repositories/picking_repository.dart';

/// Caso de uso (Query, CQRS): pedidos pendientes de preparar y cargar al camión.
///
/// Criterio de filtro: el preparador/andén trabaja los pedidos que ya llegaron
/// pero todavía no están sobre el camión. En el ciclo de vida de
/// [ShipmentStatus] eso son los estados previos a la ejecución:
///   - `received`  → recibido del backend, aún por preparar.
///   - `planned`   → planificado en una ruta, listo para preparar/cargar.
/// Se excluyen `inExecution` (ya salió/está en el camión), `delivered`,
/// `failed`, `cancelled` (terminales) y `$unknown`.
///
/// El filtrado se hace acá (y no en el endpoint) porque `GET /app/shipments`
/// sólo admite un único estado por consulta: se trae la colección completa y
/// se reduce al conjunto "por preparar/cargar".
class ListOrdersToPrepare {
  const ListOrdersToPrepare(this._repo);

  final PickingRepository _repo;

  /// Estados que la worklist del preparador considera "por preparar/cargar".
  static const Set<ShipmentStatus> toPrepareStatuses = {
    ShipmentStatus.received,
    ShipmentStatus.planned,
  };

  Future<List<Shipment>> call() async {
    final shipments = await _repo.listShipments();
    return shipments
        .where((shipment) => toPrepareStatuses.contains(shipment.status))
        .toList(growable: false);
  }
}

final listOrdersToPrepareProvider = Provider<ListOrdersToPrepare>(
  (ref) => ListOrdersToPrepare(ref.watch(pickingRepositoryProvider)),
);
