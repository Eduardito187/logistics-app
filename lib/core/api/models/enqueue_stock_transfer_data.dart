// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'enqueue_stock_transfer_data_status.dart';

part 'enqueue_stock_transfer_data.g.dart';

@JsonSerializable()
class EnqueueStockTransferData {
  const EnqueueStockTransferData({
    required this.eventId,
    required this.shipmentRef,
    required this.status,
  });

  factory EnqueueStockTransferData.fromJson(Map<String, Object?> json) =>
      _$EnqueueStockTransferDataFromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;
  final EnqueueStockTransferDataStatus status;

  Map<String, Object?> toJson() => _$EnqueueStockTransferDataToJson(this);
}
