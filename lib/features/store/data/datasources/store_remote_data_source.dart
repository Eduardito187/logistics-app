import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/delivery.dart';
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
  Future<List<Shipment>> listShipments() async {
    try {
      final response = await _ref
          .read(logisticsApiProvider)
          .shipments
          .listShipments();
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

  /// Bultos esperados de un envío (per-bulto); insumo de la recepción y del POD.
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

  /// Llamada directa al endpoint de recepción de un bulto en el nodo. La usa el
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

  /// Llamada directa al endpoint de recepción (EAN→etiqueta) de un bulto. La usa
  /// el dispatcher de la cola offline.
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
