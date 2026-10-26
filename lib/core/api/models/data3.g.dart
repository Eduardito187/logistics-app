// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data3.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data3 _$Data3FromJson(Map<String, dynamic> json) => Data3(
  status: json['status'] as String?,
  driverId: json['driver_id'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  assembledFor: json['assembled_for'] == null
      ? null
      : DateTime.parse(json['assembled_for'] as String),
);

Map<String, dynamic> _$Data3ToJson(Data3 instance) => <String, dynamic>{
  'status': instance.status,
  'driver_id': instance.driverId,
  'vehicle_id': instance.vehicleId,
  'assembled_for': instance.assembledFor?.toIso8601String(),
};
