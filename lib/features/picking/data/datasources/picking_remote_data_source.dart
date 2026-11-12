import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/logistics_api.dart';
import '../../../../core/api/models/dispatch_lines_response.dart';
import '../../../../core/api/models/emit_labels_request.dart';
import '../../../../core/api/models/emitted_label.dart';
import '../../../../core/api/models/meta_sealed.dart';
import '../../../../core/api/models/shipment_status.dart';
import '../../domain/entities/shipment_page.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';

/// Fuente de datos remota del feature de preparación (preparador / andén).
/// Única clase del feature que toca `logisticsApiProvider` / `api.labels.*`.
/// Cada método espeja un endpoint, devuelve el modelo del contrato (`.data`) y
/// convierte el error de Dio en [ApiException] (el *Failure* del dominio).
class PickingRemoteDataSource {
  const PickingRemoteDataSource(this._api, this._dio);

  final LogisticsApi _api;

  /// Dio crudo (mismo cliente autenticado) para el emit POR ORDEN con body
  /// vacío: el cliente generado exige `EmitLabelsRequest` con campos, pero el
  /// modo por orden manda `{}` y el backend deriva todo.
  final Dio _dio;

  /// GET `/app/shipments`: pedidos recibidos (worklist del preparador/andén).
  /// Con [status] el filtro va en el servidor (`status`); el endpoint admite
  /// un único estado por consulta, así que el caso de uso pide cada estado
  /// "por preparar/cargar" en paralelo.
  /// Pagina por NÚMERO DE PÁGINA. No se usa cursor porque el `meta` del
  /// cliente generado es ilegible (deserializa `perPage`/`nextCursor` en
  /// camelCase y el backend manda `per_page`/`next_page`), así que el cursor
  /// siempre vendría vacío. Antes se pedía la página 1 con 50 y el resto se
  /// perdía EN SILENCIO (en staging hay 384 pedidos: se perdían 334).
  Future<ShipmentPage> listShipments({
    ShipmentStatus? status,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _api.shipments.listShipments(
        status: status,
        page: page,
        perPage: perPage,
      );
      final items = response.data;
      return ShipmentPage(
        items: items,
        // Si el `meta` se puede leer, manda; si no, heurística: una página
        // completa puede tener continuación (a lo sumo un GET vacío al final).
        hasMore: _hasMoreOf(response.meta) ?? (items.length >= perPage),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// `true`/`false` si el `meta` sellado se pudo leer; `null` si no (hoy es lo
  /// habitual por el bug de camelCase del generador).
  static bool? _hasMoreOf(MetaSealed? meta) => switch (meta) {
    MetaSealedCursorMeta(:final hasMore) => hasMore,
    MetaSealedPaginationMeta(:final nextPage) => nextPage != null,
    _ => null,
  };

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

  /// GET `/app/orders/{orderNumber}/dispatch-lines`: los productos a etiquetar
  /// del pedido ya resueltos (nombre, SKU, foto, origen/destino por línea,
  /// autorización y estado de etiqueta). Base de la lista simple de etiquetado.
  Future<DispatchLinesResponse> getOrderDispatchLines(
    String orderNumber,
  ) async {
    try {
      return await _api.labels.getOrderDispatchLines(orderNumber: orderNumber);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// POST `/app/orders/{orderNumber}/labels` con body VACÍO: emisión POR ORDEN.
  /// El backend recorre los envíos del pedido, deriva origen/destino/líneas del
  /// plan publicado y emite SOLO las líneas autorizadas y aún pendientes. Es
  /// idempotente: reabrir la pantalla emite lo que falte, sin duplicar (201 con
  /// la colección completa). No pide nada al usuario (sin form de origen/destino).
  Future<List<EmittedLabel>> emitOrderLabels(String orderNumber) async {
    try {
      final res = await _dio.post<Map<String, Object?>>(
        '/app/orders/$orderNumber/labels',
        data: const <String, Object?>{},
      );
      final data = (res.data?['data'] as List<Object?>?) ?? const [];
      return data
          .map((e) => EmittedLabel.fromJson((e as Map).cast<String, Object?>()))
          .toList(growable: false);
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

  /// POST `/app/orders/{orderNumber}/vehicle` con body `{vehicle_id}`: ATA el
  /// pedido al vehículo en el backend (lo deja como parada de su ruta). Sin
  /// esto la asignación era solo estado local y el pedido seguía apareciendo
  /// en "Pedidos por preparar". 422 si el vehículo no existe o no está
  /// operativo; 404 si el pedido no existe. Es idempotente (reasignar no
  /// duplica). Dio crudo: el endpoint todavía no está en el cliente generado.
  Future<void> assignVehicle(String orderNumber, String vehicleId) async {
    try {
      await _dio.post<Object?>(
        '/app/orders/$orderNumber/vehicle',
        data: <String, Object?>{'vehicle_id': vehicleId},
      );
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
  (ref) => PickingRemoteDataSource(
    ref.watch(logisticsApiProvider),
    ref.watch(dioProvider),
  ),
);
