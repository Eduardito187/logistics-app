// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/emit_labels_request.dart';
import '../models/get_app_labels_public_keys_response.dart';
import '../models/label_collection.dart';
import '../models/reprint_labels_request.dart';

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

  /// Emit the label batch for an order.
  ///
  /// Emite una etiqueta por cada bulto físico de cada línea del pedido: arma el payload, lo firma y renderiza su ZPL. Reemitir una etiqueta ya emitida es un conflicto (409).
  ///
  /// [orderNumber] - Número de pedido.
  @POST('/app/orders/{orderNumber}/labels')
  Future<LabelCollection> emitShipmentLabels({
    @Path('orderNumber') required String orderNumber,
    @Body() required EmitLabelsRequest body,
  });

  /// Reprint the labels of an order.
  ///
  /// Revoca las etiquetas vigentes del pedido (quedan en la base, marcadas como revocadas para auditoría) y emite un lote nuevo con identidades nuevas. Se usa cuando una etiqueta se dañó o cambió el contenido del bulto. Requiere un motivo (ADR 004).
  ///
  /// [orderNumber] - Número de pedido.
  @POST('/app/orders/{orderNumber}/labels/reprint')
  Future<LabelCollection> reprintShipmentLabels({
    @Path('orderNumber') required String orderNumber,
    @Body() required ReprintLabelsRequest body,
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
