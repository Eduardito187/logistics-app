// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/dispatch_lines_response.dart';
import '../models/emit_labels_by_order_request.dart';
import '../models/emit_labels_request.dart';
import '../models/get_app_labels_public_keys_response.dart';
import '../models/get_app_printers_response.dart';
import '../models/label_collection.dart';
import '../models/label_unit_resolution.dart';

part 'labels_client.g.dart';

@RestApi()
abstract class LabelsClient {
  factory LabelsClient(Dio dio, {String? baseUrl}) = _LabelsClient;

  /// Public keys bundle for offline QR verification.
  ///
  /// Devuelve el conjunto de claves públicas vigentes (activa + anteriores aún aceptadas) que la app usa para verificar la firma Ed25519 de los QR sin conexión. Solo claves públicas.
  @GET('/app/labels/public-keys')
  Future<GetAppLabelsPublicKeysResponse> getLabelPublicKeys();

  /// Emitted labels of an order.
  ///
  /// Etiquetas ya emitidas del pedido, para reimprimir o sincronizar la app offline. Cada etiqueta trae su contenido de QR firmado y su ZPL.
  ///
  /// [orderNumber] - Número de pedido.
  @GET('/app/orders/{orderNumber}/labels')
  Future<LabelCollection> getShipmentLabels({
    @Path('orderNumber') required String orderNumber,
  });

  /// Emit the labels of an order.
  ///
  /// Emite las etiquetas del pedido (una por producto físico): arma el payload, lo firma y renderiza su ZPL.
  ///
  /// Dos modos sobre el mismo endpoint:.
  /// - **Lote explícito**: el cuerpo trae `origin` + `destination` + `lines`. Emite ese lote tal cual; reemitir una etiqueta ya emitida es un conflicto (409).
  /// - **Por orden** (cuerpo VACÍO, o solo con `origin`): el backend deriva origen, destino y líneas de los envíos del pedido y del plan publicado, y emite solo lo AUTORIZADO (con plan publicado) y aún PENDING. Es idempotente/parcial: reabrir la pantalla emite lo que falta sin duplicar, y responde 201 con la colección completa (no 409).
  ///
  /// [orderNumber] - Número de pedido.
  @POST('/app/orders/{orderNumber}/labels')
  Future<LabelCollection> emitShipmentLabels({
    @Path('orderNumber') required String orderNumber,
    @Body() EmitLabelsByOrderRequest? body,
  });

  /// Concatenated ZPL for the order labels.
  ///
  /// ZPL de todas las etiquetas del pedido, concatenado y listo para enviar a la impresora Zebra.
  ///
  /// [orderNumber] - Número de pedido.
  @GET('/app/orders/{orderNumber}/labels/zpl')
  Future<String> getShipmentLabelsZpl({
    @Path('orderNumber') required String orderNumber,
  });

  /// Dispatch lines of an order (per-product labeling screen).
  ///
  /// Líneas de despacho de la orden para la pantalla de etiquetado por producto: cada producto con.
  /// nombre + imagen servible, origen y destino humanos (cero uuid), el envío al que pertenece.
  /// (shipment_id opaco para agrupar + shipment_reference legible), si está AUTORIZADA (plan publicado).
  /// y el estado de su etiqueta. Forma n-a-n (destino por línea).
  ///
  /// [orderNumber] - Número de pedido.
  @GET('/app/orders/{orderNumber}/dispatch-lines')
  Future<DispatchLinesResponse> getOrderDispatchLines({
    @Path('orderNumber') required String orderNumber,
  });

  /// Resolve a scanned label to its physical unit (online fallback).
  ///
  /// FALLBACK ONLINE: resuelve una etiqueta escaneada (ULID del QR) al producto físico (unit_id) y su envío.
  /// El flujo normal es offline-first (label_id→unit_id ya viene en EmittedLabel y UnitTracking cacheados).
  ///
  /// [labelId] - Id (ULID) de la etiqueta escaneada.
  @GET('/app/labels/{labelId}/resolve')
  Future<LabelUnitResolution> resolveLabelUnit({
    @Path('labelId') required String labelId,
  });

  /// Network printers available to the user (registered centrally per site).
  ///
  /// Impresoras de red ACTIVAS registradas en el admin, para "Impresoras de tu sede". Existe porque el.
  /// teléfono no puede descubrirlas cuando WiFi y cable están en redes separadas. Alcance server-side:.
  /// supervisor/admin ven todas; el resto, las de su nodo asignado + las compartidas (sin nodo).
  /// Cambiar la IP en el admin se refleja aquí en la próxima consulta.
  @GET('/app/printers')
  Future<GetAppPrintersResponse> listAppPrinters();

  /// Pre-emit the labels of an order when a plan is published.
  ///
  /// Pre-emisión disparada por el worker/integrador al publicarse un plan (planning.plan_published): deja las etiquetas firmadas y renderizadas listas antes de preparar el pedido. Idempotente: si el pedido ya tiene etiquetas vigentes, no reemite (responde 200 con el estado actual). Puerta de procesos internos (integrations).
  ///
  /// [orderNumber] - Número de pedido.
  @POST('/integrations/orders/{orderNumber}/labels/pre-emit')
  Future<LabelCollection> preEmitOrderLabels({
    @Path('orderNumber') required String orderNumber,
    @Body() required EmitLabelsRequest body,
  });
}
