// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'assign_shipment_to_plan_request.g.dart';

@JsonSerializable()
class AssignShipmentToPlanRequest {
  const AssignShipmentToPlanRequest({
    required this.shipmentId,
    this.latitude,
    this.longitude,
  });

  factory AssignShipmentToPlanRequest.fromJson(Map<String, Object?> json) =>
      _$AssignShipmentToPlanRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() => _$AssignShipmentToPlanRequestToJson(this);
}
