// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_change_vehicle_status_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetChangeVehicleStatusData _$FleetChangeVehicleStatusDataFromJson(
  Map<String, dynamic> json,
) => FleetChangeVehicleStatusData(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  newStatus: json['new_status'] == null
      ? null
      : VehicleStatus.fromJson(json['new_status'] as String),
);

Map<String, dynamic> _$FleetChangeVehicleStatusDataToJson(
  FleetChangeVehicleStatusData instance,
) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'new_status': instance.newStatus,
};
