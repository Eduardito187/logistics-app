// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_driver_request.g.dart';

@JsonSerializable()
class RegisterDriverRequest {
  const RegisterDriverRequest({
    required this.name,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.active = true,
    this.licenseDocumentType = 'driver_license',
    this.enabledVehicleIds,
  });

  factory RegisterDriverRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterDriverRequestFromJson(json);

  final String name;
  @JsonKey(name: 'license_number')
  final String licenseNumber;
  @JsonKey(name: 'license_expiry')
  final DateTime licenseExpiry;
  @JsonKey(name: 'enabled_vehicle_ids')
  final List<String>? enabledVehicleIds;
  final bool active;
  @JsonKey(name: 'license_document_type')
  final String licenseDocumentType;

  Map<String, Object?> toJson() => _$RegisterDriverRequestToJson(this);
}
