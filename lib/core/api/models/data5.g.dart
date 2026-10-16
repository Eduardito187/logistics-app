// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data5.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data5 _$Data5FromJson(Map<String, dynamic> json) => Data5(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  newStatus: json['new_status'] == null
      ? null
      : VehicleStatus.fromJson(json['new_status'] as String),
);

Map<String, dynamic> _$Data5ToJson(Data5 instance) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'new_status': instance.newStatus,
};
