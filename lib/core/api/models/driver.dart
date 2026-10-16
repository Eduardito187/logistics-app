// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

@JsonSerializable()
class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.licenseNumber,
  });

  factory Driver.fromJson(Map<String, Object?> json) => _$DriverFromJson(json);

  final String id;
  final String? name;
  @JsonKey(name: 'license_number')
  final String? licenseNumber;

  Map<String, Object?> toJson() => _$DriverToJson(this);
}
