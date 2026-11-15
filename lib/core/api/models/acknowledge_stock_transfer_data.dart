// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'acknowledge_stock_transfer_data_status.dart';

part 'acknowledge_stock_transfer_data.g.dart';

@JsonSerializable()
class AcknowledgeStockTransferData {
  const AcknowledgeStockTransferData({
    required this.eventId,
    required this.status,
  });

  factory AcknowledgeStockTransferData.fromJson(Map<String, Object?> json) =>
      _$AcknowledgeStockTransferDataFromJson(json);

  @JsonKey(name: 'event_id')
  final String eventId;
  final AcknowledgeStockTransferDataStatus status;

  Map<String, Object?> toJson() => _$AcknowledgeStockTransferDataToJson(this);
}
