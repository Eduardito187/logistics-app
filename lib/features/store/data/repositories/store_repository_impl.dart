import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/delivery.dart';
import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/open_node_reception_request.dart';
import '../../../../core/api/models/reconcile_node_reception_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/store_remote_data_source.dart';

/// Implementación del contrato de Tienda: delega en el data source remoto, que
/// es quien habla con el cliente API.
class StoreRepositoryImpl implements StoreRepository {
  StoreRepositoryImpl(this._remote);

  final StoreRemoteDataSource _remote;

  @override
  Future<List<Node>> listNodes() => _remote.listNetworkNodes();

  @override
  Future<List<Shipment>> listShipments() => _remote.listShipments();

  @override
  Future<NodeReceptionView?> getNodeReception({
    required String shipmentId,
    required String nodeId,
  }) async {
    try {
      return await _remote.getNodeReception(
        shipmentId: shipmentId,
        nodeId: nodeId,
      );
    } on ApiException catch (e) {
      // Aún no se abrió la recepción: el backend responde 404 y la UI lo trata
      // como "sin recepción" para ofrecer "Abrir recepción".
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) =>
      _remote.getShipmentUnits(shipmentId);

  @override
  Future<Delivery> getDeliveryState(String shipmentId) =>
      _remote.getDeliveryState(shipmentId);

  @override
  Future<void> openNodeReception(OpenNodeReceptionRequest body) =>
      _remote.openNodeReception(body);

  @override
  Future<void> reconcileNodeReception(ReconcileNodeReceptionRequest body) =>
      _remote.reconcileNodeReception(body);
}

/// Provider del repositorio expuesto con el **tipo interfaz**: la presentación
/// y los casos de uso nunca ven la implementación concreta.
final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepositoryImpl(ref.watch(storeRemoteDataSourceProvider)),
);
