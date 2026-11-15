// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'crew_driver.g.dart';

/// The driver leading the crew. `name`/`license_number` are null when the driver record is missing.
@JsonSerializable()
class CrewDriver {
  const CrewDriver({
    required this.id,
    required this.name,
    required this.licenseNumber,
  });

  factory CrewDriver.fromJson(Map<String, Object?> json) =>
      _$CrewDriverFromJson(json);

  final String id;
  final String? name;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;

  Map<String, Object?> toJson() => _$CrewDriverToJson(this);
}
