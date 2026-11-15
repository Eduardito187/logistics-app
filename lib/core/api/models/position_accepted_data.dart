// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'position_accepted_data.g.dart';

@JsonSerializable()
class PositionAcceptedData {
  const PositionAcceptedData({
    required this.shipmentId,
    required this.accepted,
  });

  factory PositionAcceptedData.fromJson(Map<String, Object?> json) =>
      _$PositionAcceptedDataFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final bool accepted;

  Map<String, Object?> toJson() => _$PositionAcceptedDataToJson(this);
}
