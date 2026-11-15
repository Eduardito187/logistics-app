// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_source.dart';
import 'receive_shipment_accepted_data_status.dart';

part 'receive_shipment_accepted_data.g.dart';

@JsonSerializable()
class ReceiveShipmentAcceptedData {
  const ReceiveShipmentAcceptedData({
    required this.source,
    required this.externalId,
    required this.status,
  });

  factory ReceiveShipmentAcceptedData.fromJson(Map<String, Object?> json) =>
      _$ReceiveShipmentAcceptedDataFromJson(json);

  final OrderSource source;
  @JsonKey(name: 'external_id')
  final String externalId;
  final ReceiveShipmentAcceptedDataStatus status;

  Map<String, Object?> toJson() => _$ReceiveShipmentAcceptedDataToJson(this);
}
