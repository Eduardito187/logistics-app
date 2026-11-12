import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:logistics_app/features/store/domain/entities/shipment_page.dart';
import 'package:logistics_app/features/store/domain/repositories/store_repository.dart';
import 'package:logistics_app/features/store/domain/repositories/store_shipments_pager.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_notifier.dart';
import 'package:logistics_app/features/store/presentation/controllers/store_shipments_state.dart';

/// Repositorio de Tienda totalmente controlable por los tests. Cada método
/// delega en una función inyectada; por defecto lanza para evidenciar llamadas
/// inesperadas.
class FakeStoreRepository implements StoreRepository, StoreShipmentsPager {
  FakeStoreRepository({
    this.onListNodes,
    this.onListShipments,
    this.onListShipmentsPage,
    this.onGetNodeReception,
    this.onGetShipmentUnits,
    this.onGetDeliveryState,
    this.onOpenNodeReception,
    this.onReconcileNodeReception,
  });

  Future<List<Node>> Function()? onListNodes;
  Future<List<Shipment>> Function()? onListShipments;

  /// Página de envíos por número de página (1 en adelante). Sin esto,
  /// `listShipmentsPage` devuelve una sola página con [onListShipments]: los
  /// tests que no prueban paginación no se enteran de que existe.
  Future<ShipmentPage> Function(int page, int perPage)? onListShipmentsPage;
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

  /// Páginas pedidas (`page`, `per_page`), en orden.
  final List<({int page, int perPage})> shipmentPageRequests =
      <({int page, int perPage})>[];

  @override
  Future<ShipmentPage> listShipmentsPage({
    String? destinationNodeId,
    required int page,
    required int perPage,
  }) async {
    listShipmentsNodeIds.add(destinationNodeId);
    shipmentPageRequests.add((page: page, perPage: perPage));
    final pager = onListShipmentsPage;
    if (pager != null) return pager(page, perPage);
    if (page > 1) return ShipmentPage.empty;
    final shipments = await (onListShipments ?? (() async => <Shipment>[]))();
    return ShipmentPage(shipments: shipments, hasMore: false);
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

/// Lista de envíos controlada por el test, sin pasar por la sesión ni por el
/// repositorio (las pantallas solo necesitan el estado, no el GET).
///
/// [loadMore] no pide nada: marca "cargando más", que es lo que la pantalla
/// tiene que reflejar. La paginación de verdad se prueba sobre
/// `StoreShipmentsNotifier` con [FakeStoreRepository].
class FakeStoreShipments extends StoreShipmentsNotifier {
  FakeStoreShipments(this._load, {this.hasMore = false});

  final Future<List<Shipment>> Function() _load;
  final bool hasMore;

  /// Cuántas veces se pidió la página siguiente (scroll o botón del pie).
  int loadMoreCalls = 0;

  @override
  Future<StoreShipmentsState> build() async =>
      StoreShipmentsState(shipments: await _load(), hasMore: hasMore);

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
  }
}

/// Override de la lista de envíos de las pantallas de tienda.
Override storeShipmentsOverride(
  Future<List<Shipment>> Function() load, {
  bool hasMore = false,
}) => storeShipmentsPagedProvider.overrideWith(
  () => FakeStoreShipments(load, hasMore: hasMore),
);

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
