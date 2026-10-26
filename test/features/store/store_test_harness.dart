import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:logistics_app/core/api/models/delivery.dart';
import 'package:logistics_app/core/api/models/node.dart';
import 'package:logistics_app/core/api/models/node_reception_view.dart';
import 'package:logistics_app/core/api/models/open_node_reception_request.dart';
import 'package:logistics_app/core/api/models/reconcile_node_reception_request.dart';
import 'package:logistics_app/core/api/models/shipment.dart';
import 'package:logistics_app/core/api/models/unit_tracking.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/connectivity_notifier.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/store/domain/repositories/store_repository.dart';

/// Repositorio de Tienda totalmente controlable por los tests. Cada método
/// delega en una función inyectada; por defecto lanza para evidenciar llamadas
/// inesperadas.
class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository({
    this.onListNodes,
    this.onListShipments,
    this.onGetNodeReception,
    this.onGetShipmentUnits,
    this.onGetDeliveryState,
    this.onOpenNodeReception,
    this.onReconcileNodeReception,
  });

  Future<List<Node>> Function()? onListNodes;
  Future<List<Shipment>> Function()? onListShipments;
  Future<NodeReceptionView?> Function(String shipmentId, String nodeId)?
  onGetNodeReception;
  Future<List<UnitTracking>> Function(String shipmentId)? onGetShipmentUnits;
  Future<Delivery> Function(String shipmentId)? onGetDeliveryState;
  Future<void> Function(OpenNodeReceptionRequest body)? onOpenNodeReception;
  Future<void> Function(ReconcileNodeReceptionRequest body)?
  onReconcileNodeReception;

  int openCalls = 0;
  int reconcileCalls = 0;
  OpenNodeReceptionRequest? lastOpenRequest;
  ReconcileNodeReceptionRequest? lastReconcileRequest;

  @override
  Future<List<Node>> listNodes() => (onListNodes ?? (() async => <Node>[]))();

  /// Nodo destino pedido en cada `listShipments` (filtro de servidor).
  final List<String?> listShipmentsNodeIds = <String?>[];

  @override
  Future<List<Shipment>> listShipments({String? destinationNodeId}) {
    listShipmentsNodeIds.add(destinationNodeId);
    return (onListShipments ?? (() async => <Shipment>[]))();
  }

  @override
  Future<NodeReceptionView?> getNodeReception({
    required String shipmentId,
    required String nodeId,
  }) => (onGetNodeReception ?? ((_, _) async => null))(shipmentId, nodeId);

  @override
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) =>
      (onGetShipmentUnits ?? ((_) async => <UnitTracking>[]))(shipmentId);

  @override
  Future<Delivery> getDeliveryState(String shipmentId) =>
      (onGetDeliveryState ??
      ((_) async => throw UnimplementedError('getDeliveryState')))(shipmentId);

  @override
  Future<void> openNodeReception(OpenNodeReceptionRequest body) async {
    openCalls++;
    lastOpenRequest = body;
    if (onOpenNodeReception != null) await onOpenNodeReception!(body);
  }

  @override
  Future<void> reconcileNodeReception(
    ReconcileNodeReceptionRequest body,
  ) async {
    reconcileCalls++;
    lastReconcileRequest = body;
    if (onReconcileNodeReception != null) await onReconcileNodeReception!(body);
  }
}

/// Conectividad fija (siempre en línea) que NO toca el plugin connectivity_plus.
class _StubConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

/// Overrides para que el [SyncBadge] de las AppBars renderice sin Drift ni el
/// plugin de conectividad (cola vacía, en línea).
List<Override> syncBadgeOverrides() => [
  syncQueueProvider.overrideWith((ref) => Stream.value(<OutboxAction>[])),
  connectivityProvider.overrideWith(_StubConnectivity.new),
];
