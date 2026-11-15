// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shipments.dart';

part 'assign_order_vehicle_data.g.dart';

@JsonSerializable()
class AssignOrderVehicleData {
  const AssignOrderVehicleData({
    required this.orderReference,
    required this.vehicleId,
    required this.plate,
    required this.shipments,
  });

  factory AssignOrderVehicleData.fromJson(Map<String, Object?> json) =>
      _$AssignOrderVehicleDataFromJson(json);

  @JsonKey(name: 'order_reference')
  final String orderReference;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final String plate;
  final List<Shipments> shipments;

  Map<String, Object?> toJson() => _$AssignOrderVehicleDataToJson(this);
}
