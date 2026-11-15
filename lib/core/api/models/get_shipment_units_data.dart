// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unit_tracking.dart';

part 'get_shipment_units_data.g.dart';

@JsonSerializable()
class GetShipmentUnitsData {
  const GetShipmentUnitsData({required this.shipmentId, required this.units});

  factory GetShipmentUnitsData.fromJson(Map<String, Object?> json) =>
      _$GetShipmentUnitsDataFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final List<UnitTracking> units;

  Map<String, Object?> toJson() => _$GetShipmentUnitsDataToJson(this);
}
