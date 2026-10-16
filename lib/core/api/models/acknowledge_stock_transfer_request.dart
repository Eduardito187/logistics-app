// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'acknowledge_stock_transfer_request.g.dart';

@JsonSerializable()
class AcknowledgeStockTransferRequest {
  const AcknowledgeStockTransferRequest({required this.eventId});

  factory AcknowledgeStockTransferRequest.fromJson(Map<String, Object?> json) =>
      _$AcknowledgeStockTransferRequestFromJson(json);

  /// Clave de idempotencia (event_id de la recepción) que SAP recibió al empujarse el traspaso
  @JsonKey(name: 'event_id')
  final String eventId;

  Map<String, Object?> toJson() =>
      _$AcknowledgeStockTransferRequestToJson(this);
}
