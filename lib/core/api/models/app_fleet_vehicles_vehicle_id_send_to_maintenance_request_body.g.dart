// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_fleet_vehicles_vehicle_id_send_to_maintenance_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody
_$AppFleetVehiclesVehicleIdSendToMaintenanceRequestBodyFromJson(
  Map<String, dynamic> json,
) => AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody(
  workshop: json['workshop'] as String?,
  note: json['note'] as String?,
  odometerKm: (json['odometer_km'] as num?)?.toInt(),
  scheduledAt: json['scheduled_at'] == null
      ? null
      : DateTime.parse(json['scheduled_at'] as String),
  reassignToVehicleId: json['reassign_to_vehicle_id'] as String?,
  type: json['type'] == null
      ? Type.corrective
      : Type.fromJson(json['type'] as String),
);

Map<String, dynamic>
_$AppFleetVehiclesVehicleIdSendToMaintenanceRequestBodyToJson(
  AppFleetVehiclesVehicleIdSendToMaintenanceRequestBody instance,
) => <String, dynamic>{
  'type': instance.type,
  'workshop': instance.workshop,
  'note': instance.note,
  'odometer_km': instance.odometerKm,
  'scheduled_at': instance.scheduledAt?.toIso8601String(),
  'reassign_to_vehicle_id': instance.reassignToVehicleId,
};
