// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_send_vehicle_to_maintenance_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetSendVehicleToMaintenanceData _$FleetSendVehicleToMaintenanceDataFromJson(
  Map<String, dynamic> json,
) => FleetSendVehicleToMaintenanceData(
  status: json['status'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  newStatus: json['new_status'] as String?,
  route: json['route'] == null
      ? null
      : MaintenanceRouteOutcome.fromJson(json['route'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FleetSendVehicleToMaintenanceDataToJson(
  FleetSendVehicleToMaintenanceData instance,
) => <String, dynamic>{
  'status': instance.status,
  'vehicle_id': instance.vehicleId,
  'new_status': instance.newStatus,
  'route': instance.route,
};
