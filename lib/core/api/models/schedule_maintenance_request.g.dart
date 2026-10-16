// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_maintenance_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleMaintenanceRequest _$ScheduleMaintenanceRequestFromJson(
  Map<String, dynamic> json,
) => ScheduleMaintenanceRequest(
  vehicleId: json['vehicle_id'] as String,
  type: ScheduleMaintenanceRequestType.fromJson(json['type'] as String),
  scheduledAt: DateTime.parse(json['scheduled_at'] as String),
  odometerKm: (json['odometer_km'] as num?)?.toInt(),
  workshop: json['workshop'] as String?,
  note: json['note'] as String?,
);

Map<String, dynamic> _$ScheduleMaintenanceRequestToJson(
  ScheduleMaintenanceRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'type': instance.type,
  'odometer_km': instance.odometerKm,
  'workshop': instance.workshop,
  'scheduled_at': instance.scheduledAt.toIso8601String(),
  'note': instance.note,
};
