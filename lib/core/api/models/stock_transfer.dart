// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'stock_transfer_status.dart';

part 'stock_transfer.g.dart';

@JsonSerializable()
class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.eventId,
    required this.shipmentRef,
    required this.material,
    required this.center,
    required this.warehouse,
    required this.quantity,
    required this.status,
    this.lastError,
  });

  factory StockTransfer.fromJson(Map<String, Object?> json) =>
      _$StockTransferFromJson(json);

  final String id;
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;

  /// Material SAP (resultado de la traducción del sku propio)
  final String material;
  final String center;
  final String warehouse;
  final int quantity;
  final StockTransferStatus status;
  @JsonKey(name: 'last_error')
  final String? lastError;

  Map<String, Object?> toJson() => _$StockTransferToJson(this);
}
