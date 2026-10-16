// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
  id: json['id'] as String,
  name: json['name'] as String?,
  licenseNumber: json['license_number'] as String?,
);

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'license_number': instance.licenseNumber,
};
