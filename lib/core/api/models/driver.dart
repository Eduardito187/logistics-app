// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

@JsonSerializable()
class Driver {
  const Driver({
    this.id,
    this.name,
    this.licenseNumber,
    this.licenseExpiry,
    this.enabledVehicleIds,
    this.active,
  });

  factory Driver.fromJson(Map<String, Object?> json) => _$DriverFromJson(json);

  final String? id;
  final String? name;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;
  @JsonKey(name: 'license_expiry')
  final DateTime? licenseExpiry;
  @JsonKey(name: 'enabled_vehicle_ids')
  final List<String>? enabledVehicleIds;
  final bool? active;

  Map<String, Object?> toJson() => _$DriverToJson(this);
}
