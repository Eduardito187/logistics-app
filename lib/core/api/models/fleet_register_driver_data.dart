// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_register_driver_data.g.dart';

@JsonSerializable()
class FleetRegisterDriverData {
  const FleetRegisterDriverData({this.status, this.licenseNumber});

  factory FleetRegisterDriverData.fromJson(Map<String, Object?> json) =>
      _$FleetRegisterDriverDataFromJson(json);

  final String? status;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;

  Map<String, Object?> toJson() => _$FleetRegisterDriverDataToJson(this);
}
