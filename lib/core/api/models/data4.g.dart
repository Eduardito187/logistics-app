// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data4.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data4 _$Data4FromJson(Map<String, dynamic> json) => Data4(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  driverId: json['driver_id'] as String?,
  performedOn: json['performed_on'] == null
      ? null
      : DateTime.parse(json['performed_on'] as String),
);

Map<String, dynamic> _$Data4ToJson(Data4 instance) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'performed_on': instance.performedOn?.toIso8601String(),
};
