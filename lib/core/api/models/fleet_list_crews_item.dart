// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'helpers.dart';

part 'fleet_list_crews_item.g.dart';

@JsonSerializable()
class FleetListCrewsItem {
  const FleetListCrewsItem({
    this.id,
    this.assembledFor,
    this.vehicleId,
    this.vehiclePlate,
    this.driverId,
    this.driverName,
    this.helpers,
    this.shiftStartsAt,
    this.shiftEndsAt,
  });

  factory FleetListCrewsItem.fromJson(Map<String, Object?> json) =>
      _$FleetListCrewsItemFromJson(json);

  final String? id;
  @JsonKey(name: 'assembled_for')
  final DateTime? assembledFor;
  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  final List<Helpers>? helpers;
  @JsonKey(name: 'shift_starts_at')
  final DateTime? shiftStartsAt;
  @JsonKey(name: 'shift_ends_at')
  final DateTime? shiftEndsAt;

  Map<String, Object?> toJson() => _$FleetListCrewsItemToJson(this);
}
