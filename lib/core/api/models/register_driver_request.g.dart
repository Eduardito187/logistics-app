// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_driver_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDriverRequest _$RegisterDriverRequestFromJson(
  Map<String, dynamic> json,
) => RegisterDriverRequest(
  name: json['name'] as String,
  licenseNumber: json['license_number'] as String,
  licenseExpiry: DateTime.parse(json['license_expiry'] as String),
  active: json['active'] as bool? ?? true,
  licenseDocumentType:
      json['license_document_type'] as String? ?? 'driver_license',
  enabledVehicleIds: (json['enabled_vehicle_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$RegisterDriverRequestToJson(
  RegisterDriverRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'license_number': instance.licenseNumber,
  'license_expiry': instance.licenseExpiry.toIso8601String(),
  'enabled_vehicle_ids': instance.enabledVehicleIds,
  'active': instance.active,
  'license_document_type': instance.licenseDocumentType,
};
