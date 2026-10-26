import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/logistics_api.dart';
import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/reprint_labels_request.dart';
import '../../../../core/api/models/shipment.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Fuente de datos remota del feature de preparación (preparador / andén).
/// Única clase del feature que toca `logisticsApiProvider` / `api.labels.*`.
/// Cada método espeja un endpoint, devuelve el modelo del contrato (`.data`) y
/// convierte el error de Dio en [ApiException] (el *Failure* del dominio).
class PickingRemoteDataSource {
  const PickingRemoteDataSource(this._api);

  final LogisticsApi _api;

  /// GET `/app/shipments`: pedidos recibidos (worklist del preparador/andén).
  /// Con [status] el filtro va en el servidor (`status`); el endpoint admite
  /// un único estado por consulta, así que el caso de uso pide cada estado
  /// "por preparar/cargar" en paralelo.
  Future<List<Shipment>> listShipments({ShipmentStatus? status}) async {
    try {
      final response = await _api.shipments.listShipments(status: status);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/orders/{orderNumber}/labels`: etiquetas ya emitidas del pedido.
  Future<List<EmittedLabel>> getOrderLabels(String orderNumber) async {
    try {
      final collection = await _api.labels.getShipmentLabels(
        orderNumber: orderNumber,
      );
      return collection.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/orders/{orderNumber}/labels`: emite el lote de etiquetas.
  /// Lanza [ApiException] (incluye 409 si ya hay etiquetas vigentes).
  Future<List<EmittedLabel>> emitLabels(
    String orderNumber,
    EmitLabelsRequest body,
  ) async {
    try {
      final collection = await _api.labels.emitShipmentLabels(
        orderNumber: orderNumber,
        body: body,
      );
      return collection.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/orders/{orderNumber}/labels/reprint`: revoca las etiquetas
  /// vigentes y emite un lote nuevo (motivo obligatorio, ADR 004).
  Future<List<EmittedLabel>> reprintLabels(
    String orderNumber,
    ReprintLabelsRequest body,
  ) async {
    try {
      final collection = await _api.labels.reprintShipmentLabels(
        orderNumber: orderNumber,
        body: body,
      );
      return collection.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET `/app/orders/{orderNumber}/labels/zpl`: ZPL firmado por el backend
  /// (todas las etiquetas concatenadas), ruta principal de impresión Zebra.
  Future<String> getSignedZpl(String orderNumber) async {
    try {
      return await _api.labels.getShipmentLabelsZpl(orderNumber: orderNumber);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

/// Proveedor de la fuente de datos remota de preparación.
final pickingRemoteDataSourceProvider = Provider<PickingRemoteDataSource>(
  (ref) => PickingRemoteDataSource(ref.watch(logisticsApiProvider)),
);
