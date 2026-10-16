// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'enqueue_stock_transfer_request.g.dart';

@JsonSerializable()
class EnqueueStockTransferRequest {
  const EnqueueStockTransferRequest({
    required this.eventId,
    required this.shipmentRef,
    required this.sku,
    required this.quantity,
  });

  factory EnqueueStockTransferRequest.fromJson(Map<String, Object?> json) =>
      _$EnqueueStockTransferRequestFromJson(json);

  /// Identificador de la recepción que origina el traspaso (respalda la idempotencia)
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;

  /// SKU propio de la plataforma (el conector lo traduce a la coordenada SAP)
  final String sku;
  final int quantity;

  Map<String, Object?> toJson() => _$EnqueueStockTransferRequestToJson(this);
}
