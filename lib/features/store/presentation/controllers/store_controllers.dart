import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/scan_type.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/performance/cache_for.dart';
import '../../domain/usecases/get_delivery_state.dart';
import '../../domain/usecases/get_node_reception.dart';
import '../../domain/usecases/get_shipment_units.dart';
import '../../domain/usecases/list_nodes.dart';
import 'store_shipments_notifier.dart';

/// Clave de una recepción: envío + nodo destino. Record con igualdad estructural
/// para usarse como argumento de familia de providers.
typedef ReceptionKey = ({String shipmentId, String nodeId});

/// Nodos activos de la red (candidatos a tienda/nodo de recepción). Casi no
/// cambian en el turno: caché larga.
final storeNodesProvider = FutureProvider.autoDispose<List<Node>>((ref) {
  ref.cacheFor(CacheTtl.long);
  return ref.watch(listNodesProvider).call();
});

/// Envíos que llegan a la tienda del usuario (solo la lista acumulada).
///
/// Vista de lectura de [storeShipmentsPagedProvider] para quien solo necesita
/// los envíos y no el estado del scroll infinito (el widget de inicio, la
/// precarga del home). Las pantallas de tienda miran el provider paginado.
final storeShipmentsProvider = Provider.autoDispose<AsyncValue<List<Shipment>>>(
  (ref) => ref
      .watch(storeShipmentsPagedProvider)
      .whenData((state) => state.shipments),
);

/// Estado de la recepción de un envío en un nodo. `null` cuando aún no se abrió
/// (el backend responde 404), lo que la UI usa para ofrecer "Abrir recepción".
final nodeReceptionProvider = FutureProvider.autoDispose
    .family<NodeReceptionView?, ReceptionKey>(
      (ref, key) => ref
          .watch(getNodeReceptionProvider)
          .call(shipmentId: key.shipmentId, nodeId: key.nodeId),
    );

/// Productos esperados de un envío (uno por unidad física); insumo de la
/// recepción y del POD. Caché corta: entrar y salir del detalle no los vuelve a pedir.
final shipmentUnitsProvider = FutureProvider.autoDispose
    .family<List<UnitTracking>, String>((ref, shipmentId) {
      ref.cacheFor(CacheTtl.short);
      return ref.watch(getShipmentUnitsProvider).call(shipmentId);
    });

/// Productos de un envío que el SERVIDOR ya tiene como entregados (escaneos de
/// tipo prueba de entrega). Siembra la lista en memoria del POD de mostrador:
/// si el sistema operativo mata la app o el operario sale y vuelve a mitad del
/// retiro, lo ya entregado sigue bloqueado y no se encola un POD duplicado.
///
/// Degrada a vacío (regla 4, offline-first): sin red, con 404 (todavía no hay
/// entrega abierta) o ante cualquier fallo devuelve el conjunto vacío en lugar
/// de propagar el error, para que la falta de señal nunca trabe el retiro. Lo
/// entregado en esta sesión lo sigue cubriendo la memoria de la pantalla.
/// Caché corta, como el resto de los providers de pantalla.
final deliveredUnitIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, shipmentId) async {
      ref.cacheFor(CacheTtl.short);
      try {
        final delivery = await ref.watch(getDeliveryStateProvider)(shipmentId);
        return {
          for (final scan in delivery.scans)
            if (scan.type == ScanType.proofOfDelivery) scan.unitId,
        };
      } on Object {
        return const <String>{};
      }
    });
