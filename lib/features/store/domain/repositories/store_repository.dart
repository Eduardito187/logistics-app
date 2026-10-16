import '../../../../core/api/models/delivery.dart';
import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/open_node_reception_request.dart';
import '../../../../core/api/models/reconcile_node_reception_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';

/// Contrato de acceso a datos del feature Tienda. La capa de `data` lo
/// implementa; los casos de uso dependen de esta interfaz, no del cliente API.
///
/// Solo expone las lecturas y las escrituras que requieren red (abrir y
/// conciliar). Las escrituras de terreno (recibir bulto, POD, foto) se encolan
/// offline desde sus casos de uso y no viven en el repositorio.
abstract interface class StoreRepository {
  /// Nodos activos de la red (candidatos a tienda/nodo de recepción).
  Future<List<Node>> listNodes();

  /// Envíos visibles para recepción / entrega en mostrador.
  Future<List<Shipment>> listShipments();

  /// Estado de la recepción de un envío en un nodo. `null` cuando aún no se
  /// abrió (el backend responde 404), lo que la UI usa para ofrecer "Abrir".
  Future<NodeReceptionView?> getNodeReception({
    required String shipmentId,
    required String nodeId,
  });

  /// Bultos esperados de un envío (per-bulto).
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId);

  /// Estado de la entrega de un envío con sus escaneos (solo lectura).
  Future<Delivery> getDeliveryState(String shipmentId);

  /// Abre la recepción de un envío en el nodo destino (requiere red).
  Future<void> openNodeReception(OpenNodeReceptionRequest body);

  /// Concilia y cierra la recepción (requiere red).
  Future<void> reconcileNodeReception(ReconcileNodeReceptionRequest body);
}
