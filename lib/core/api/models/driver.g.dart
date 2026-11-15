// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
  id: json['id'] as String?,
  name: json['name'] as String?,
  licenseNumber: json['license_number'] as String?,
  licenseExpiry: json['license_expiry'] == null
      ? null
      : DateTime.parse(json['license_expiry'] as String),
  enabledVehicleIds: (json['enabled_vehicle_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  active: json['active'] as bool?,
);

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'license_number': instance.licenseNumber,
  'license_expiry': instance.licenseExpiry?.toIso8601String(),
  'enabled_vehicle_ids': instance.enabledVehicleIds,
  'active': instance.active,
};
