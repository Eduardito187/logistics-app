// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'fleet_register_helper_data.g.dart';

@JsonSerializable()
class FleetRegisterHelperData {
  const FleetRegisterHelperData({this.status, this.name});

  factory FleetRegisterHelperData.fromJson(Map<String, Object?> json) =>
      _$FleetRegisterHelperDataFromJson(json);

  final String? status;
  final String? name;

  Map<String, Object?> toJson() => _$FleetRegisterHelperDataToJson(this);
}
