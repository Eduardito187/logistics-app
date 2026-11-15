// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_config_field.g.dart';

@JsonSerializable()
class AppConfigField {
  const AppConfigField({required this.geofenceRadiusM});

  factory AppConfigField.fromJson(Map<String, Object?> json) =>
      _$AppConfigFieldFromJson(json);

  @JsonKey(name: 'geofence_radius_m')
  final int geofenceRadiusM;

  Map<String, Object?> toJson() => _$AppConfigFieldToJson(this);
}
