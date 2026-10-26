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
///   - `planned`   → planificado en una ruta, listo para preparar/cargar.
///   - `received`  → recibido del backend, aún por preparar.
/// La lista sale en ese orden (primero lo que ya tiene ruta: es lo que sale
/// antes) y, dentro de cada estado, en el orden del servidor.
/// Se excluyen `inExecution` (ya salió/está en el camión), `delivered`,
/// `failed`, `cancelled` (terminales) y `$unknown`.
///
/// El filtro va en el servidor: `GET /app/shipments` admite un único estado
/// por consulta, así que se pide uno por estado en paralelo y se unen (sin
/// duplicados, por id). Antes se bajaba la primera página SIN filtro (50
/// pedidos de cualquier estado) y se filtraba acá: pedidos por preparar más
/// allá de esa página no aparecían. Se mantiene un filtro defensivo en el
/// cliente por si el servidor ignora el parámetro.
class ListOrdersToPrepare {
  const ListOrdersToPrepare(this._repo);

  final PickingRepository _repo;

  /// Estados que la worklist del preparador considera "por preparar/cargar".
  static const Set<ShipmentStatus> toPrepareStatuses = {
    ShipmentStatus.planned,
    ShipmentStatus.received,
  };

  Future<List<Shipment>> call() async {
    final pages = await Future.wait([
      for (final status in toPrepareStatuses)
        _repo
            .listShipments(status: status)
            .then((list) => list.where((s) => s.status == status)),
    ]);
    final seen = <String>{};
    return [
      for (final page in pages)
        for (final shipment in page)
          if (seen.add(shipment.id)) shipment,
    ];
  }
}

final listOrdersToPrepareProvider = Provider<ListOrdersToPrepare>(
  (ref) => ListOrdersToPrepare(ref.watch(pickingRepositoryProvider)),
);
