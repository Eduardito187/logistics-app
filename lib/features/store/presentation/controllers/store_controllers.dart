import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_node_reception.dart';
import '../../domain/usecases/get_shipment_units.dart';
import '../../domain/usecases/list_nodes.dart';
import '../../domain/usecases/list_shipments.dart';
import 'selected_store_node_notifier.dart';

/// Clave de una recepción: envío + nodo destino. Record con igualdad estructural
/// para usarse como argumento de familia de providers.
typedef ReceptionKey = ({String shipmentId, String nodeId});

/// Nodos activos de la red (candidatos a tienda/nodo de recepción). Casi no
/// cambian en el turno: caché larga.
final storeNodesProvider = FutureProvider.autoDispose<List<Node>>((ref) {
  ref.cacheFor(CacheTtl.long);
  return ref.watch(listNodesProvider).call();
});

/// Envíos que llegan a la tienda del usuario, para recepción y entrega en
/// mostrador (las dos pantallas comparten este provider).
///
/// - Filtro en el servidor por `destination_node_id` = tienda de la sesión.
/// - Caché corta: ir de Recepción a Recojo (o volver de un detalle) muestra la
///   lista al instante, sin spinner ni otro GET. Al refrescar, el dato previo
///   sigue visible (`AsyncValueView` salta la carga en recargas).
final storeShipmentsProvider = FutureProvider.autoDispose<List<Shipment>>((
  ref,
) {
  ref.cacheFor(CacheTtl.short);
  final nodeId = ref.watch(selectedStoreNodeProvider.select((n) => n?.id));
  return ref.watch(listShipmentsProvider).call(destinationNodeId: nodeId);
});

/// Estado de la recepción de un envío en un nodo. `null` cuando aún no se abrió
/// (el backend responde 404), lo que la UI usa para ofrecer "Abrir recepción".
final nodeReceptionProvider = FutureProvider.autoDispose
    .family<NodeReceptionView?, ReceptionKey>(
      (ref, key) => ref
          .watch(getNodeReceptionProvider)
          .call(shipmentId: key.shipmentId, nodeId: key.nodeId),
    );

/// Bultos esperados de un envío (per-bulto); insumo de la recepción y del POD.
/// Caché corta: entrar y salir del detalle no los vuelve a pedir.
final shipmentUnitsProvider = FutureProvider.autoDispose
    .family<List<UnitTracking>, String>((ref, shipmentId) {
      ref.cacheFor(CacheTtl.short);
      return ref.watch(getShipmentUnitsProvider).call(shipmentId);
    });
