// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data6.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data6 _$Data6FromJson(Map<String, dynamic> json) => Data6(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  newStatus: json['new_status'] == null
      ? null
      : VehicleStatus.fromJson(json['new_status'] as String),
);

Map<String, dynamic> _$Data6ToJson(Data6 instance) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'new_status': instance.newStatus,
};
