import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../domain/usecases/get_node_reception.dart';
import '../../domain/usecases/get_shipment_units.dart';
import '../../domain/usecases/list_nodes.dart';
import '../../domain/usecases/list_shipments.dart';

/// Clave de una recepción: envío + nodo destino. Record con igualdad estructural
/// para usarse como argumento de familia de providers.
typedef ReceptionKey = ({String shipmentId, String nodeId});

/// Nodos activos de la red (candidatos a tienda/nodo de recepción).
final storeNodesProvider = FutureProvider.autoDispose<List<Node>>(
  (ref) => ref.watch(listNodesProvider).call(),
);

/// Envíos visibles para recepción / entrega en mostrador.
final storeShipmentsProvider = FutureProvider.autoDispose<List<Shipment>>(
  (ref) => ref.watch(listShipmentsProvider).call(),
);

/// Estado de la recepción de un envío en un nodo. `null` cuando aún no se abrió
/// (el backend responde 404), lo que la UI usa para ofrecer "Abrir recepción".
final nodeReceptionProvider = FutureProvider.autoDispose
    .family<NodeReceptionView?, ReceptionKey>(
      (ref, key) => ref
          .watch(getNodeReceptionProvider)
          .call(shipmentId: key.shipmentId, nodeId: key.nodeId),
    );

/// Bultos esperados de un envío (per-bulto); insumo de la recepción y del POD.
final shipmentUnitsProvider = FutureProvider.autoDispose
    .family<List<UnitTracking>, String>(
      (ref, shipmentId) => ref.watch(getShipmentUnitsProvider).call(shipmentId),
    );
