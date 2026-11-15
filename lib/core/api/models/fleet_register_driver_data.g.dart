// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_register_driver_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetRegisterDriverData _$FleetRegisterDriverDataFromJson(
  Map<String, dynamic> json,
) => FleetRegisterDriverData(
  status: json['status'] as String?,
  licenseNumber: json['license_number'] as String?,
);

Map<String, dynamic> _$FleetRegisterDriverDataToJson(
  FleetRegisterDriverData instance,
) => <String, dynamic>{
  'status': instance.status,
  'license_number': instance.licenseNumber,
};
