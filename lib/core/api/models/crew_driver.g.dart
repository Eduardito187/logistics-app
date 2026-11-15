// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crew_driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrewDriver _$CrewDriverFromJson(Map<String, dynamic> json) => CrewDriver(
  id: json['id'] as String,
  name: json['name'] as String?,
  licenseNumber: json['license_number'] as String?,
);

Map<String, dynamic> _$CrewDriverToJson(CrewDriver instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'license_number': instance.licenseNumber,
    };
