import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/data.dart';
import '../../../../core/api/models/delivery.dart';
import '../../../../core/api/models/enum0.dart';
import '../../../../core/api/models/meta_sealed.dart';
import '../../../../core/api/models/node.dart';
import '../../../../core/api/models/node_reception_request.dart';
import '../../../../core/api/models/node_reception_view.dart';
import '../../../../core/api/models/node_status.dart';
import '../../../../core/api/models/open_node_reception_request.dart';
import '../../../../core/api/models/proof_of_delivery_request.dart';
import '../../../../core/api/models/receive_unit_at_node_request.dart';
import '../../../../core/api/models/reconcile_node_reception_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/unit_tracking.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/shipment_page.dart';

/// Única clase del feature Tienda que toca `logisticsApiProvider` / `api.*`.
///
/// Cada método espeja un endpoint (`api.execution`, `api.shipments`,
/// `api.tracking`, `api.network`), devuelve el modelo generado desde `.data` y
/// normaliza el error de red a [ApiException]. Las escrituras de terreno
/// (escaneos) no pasan por acá en línea: sus casos de uso las encolan offline;
/// los métodos directos de escritura existen para el dispatcher de la cola.
class StoreRemoteDataSource {
  StoreRemoteDataSource(this._ref);

  final Ref _ref;

  /// Nodos activos de la red (candidatos a tienda/nodo de recepción).
  Future<List<Node>> listNetworkNodes() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .network
          .listNetworkNodes(status: NodeStatus.active);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Envíos visibles para recepción / entrega en mostrador.
  ///
  /// Con [destinationNodeId] el filtro va en el servidor
  /// (`destination_node_id`): la tienda solo baja los envíos que llegan a su
  /// nodo (antes bajaba los primeros 50 de TODAS las tiendas).
  Future<List<Shipment>> listShipments({String? destinationNodeId}) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .shipments
          .listShipments(destinationNodeId: destinationNodeId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Una página de envíos del nodo ([page] desde 1, [perPage] ≤ 200). El
  /// cliente generado tiene `page = 1, per_page = 50` por defecto: sin mandar
  /// estos parámetros una tienda con más de 50 envíos perdía el resto en
  /// silencio.
  Future<ShipmentPage> listShipmentsPage({
    String? destinationNodeId,
    required int page,
    required int perPage,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .shipments
          .listShipments(
            destinationNodeId: destinationNodeId,
            page: page,
            perPage: perPage,
          );
      return ShipmentPage(
        shipments: response.data,
        hasMore: _hasMoreAfter(response.meta, response.data.length, perPage),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Si queda otra página después de la recién traída.
  ///
  /// El backend manda `meta` con `page/per_page/total/total_pages/next_page`,
  /// pero el modelo generado [MetaSealed] deserializa sus variantes con claves
  /// camelCase (`per_page` → `perPage`), así que una respuesta real nunca
  /// encaja en [MetaSealedPaginationMeta] y cae en la variante "solo count".
  /// Por eso se usa `meta` cuando SÍ se puede leer (si el generador se
  /// arregla, esto empieza a funcionar solo) y, si no, se deduce por tamaño:
  /// una página completa significa que puede haber más. El costo del heurístico
  /// es, como máximo, un GET extra que vuelve vacío.
  bool _hasMoreAfter(MetaSealed? meta, int received, int perPage) =>
      switch (meta) {
        MetaSealedPaginationMeta(:final nextPage) => nextPage != null,
        MetaSealedCursorMeta(:final hasMore) => hasMore,
        _ => received >= perPage,
      };

  /// Sube la foto de evidencia del POD y devuelve `{disk, path, url}`: `path`
  /// es la referencia durable que el backend espera en `photo_path` de la
  /// prueba de entrega. Requiere red; el fallback offline lo decide el caso de
  /// uso (ver `UploadPodPhoto`).
  Future<Data> uploadDeliveryPhoto({
    required String shipmentId,
    required File photo,
    Enum0 kind = Enum0.pod,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .uploadDeliveryPhoto(
            shipmentId: shipmentId,
            photo: photo,
            kind: kind,
          );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Estado de la recepción de un envío en un nodo. El backend responde 404
  /// cuando aún no se abrió; esa traducción a "sin recepción" vive en el
  /// repositorio, acá solo se normaliza el error.
  Future<NodeReceptionView> getNodeReception({
    required String shipmentId,
    required String nodeId,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .getNodeReception(shipmentId: shipmentId, nodeId: nodeId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Productos esperados de un envío (uno por unidad física); insumo de la
  /// recepción y del POD.
  Future<List<UnitTracking>> getShipmentUnits(String shipmentId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .tracking
          .getShipmentUnits(shipmentId: shipmentId);
      return response.data.units;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Estado de la entrega de un envío con sus escaneos (solo lectura).
  Future<Delivery> getDeliveryState(String shipmentId) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .getDeliveryState(shipmentId: shipmentId);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Abre la recepción de un envío en el nodo destino (requiere red).
  Future<NodeReceptionView> openNodeReception(
    OpenNodeReceptionRequest body,
  ) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .openNodeReception(body: body);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Concilia y cierra la recepción (faltantes/sobrantes) (requiere red).
  Future<NodeReceptionView> reconcileNodeReception(
    ReconcileNodeReceptionRequest body,
  ) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .reconcileNodeReception(body: body);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Llamada directa al endpoint de recepción de un producto en el nodo. La usa el
  /// dispatcher de la cola offline; en terreno el escaneo se encola primero.
  Future<NodeReceptionView> receiveUnitAtNode(
    ReceiveUnitAtNodeRequest body, {
    String? idempotencyKey,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .receiveUnitAtNode(body: body, idempotencyKey: idempotencyKey);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Llamada directa al endpoint de recepción (EAN→etiqueta) de un producto.
  /// La usa el dispatcher de la cola offline.
  Future<Delivery> recordNodeReception(
    NodeReceptionRequest body, {
    String? idempotencyKey,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .recordNodeReception(body: body, idempotencyKey: idempotencyKey);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Llamada directa al endpoint de prueba de entrega. La usa el dispatcher de
  /// la cola offline; en terreno el POD se encola primero.
  Future<Delivery> recordProofOfDelivery(
    ProofOfDeliveryRequest body, {
    String? idempotencyKey,
  }) async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .execution
          .recordProofOfDelivery(body: body, idempotencyKey: idempotencyKey);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final storeRemoteDataSourceProvider = Provider<StoreRemoteDataSource>(
  StoreRemoteDataSource.new,
);
