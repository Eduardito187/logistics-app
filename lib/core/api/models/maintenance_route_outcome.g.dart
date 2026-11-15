// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_route_outcome.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceRouteOutcome _$MaintenanceRouteOutcomeFromJson(
  Map<String, dynamic> json,
) => MaintenanceRouteOutcome(
  pendingStops: (json['pending_stops'] as num?)?.toInt(),
  reassignedToVehicleId: json['reassigned_to_vehicle_id'] as String?,
  reassigned: (json['reassigned'] as List<dynamic>?)
      ?.map((e) => MaintenanceRouteOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
  pendingReassignment: (json['pending_reassignment'] as List<dynamic>?)
      ?.map((e) => MaintenanceRouteOrder.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MaintenanceRouteOutcomeToJson(
  MaintenanceRouteOutcome instance,
) => <String, dynamic>{
  'pending_stops': instance.pendingStops,
  'reassigned_to_vehicle_id': instance.reassignedToVehicleId,
  'reassigned': instance.reassigned,
  'pending_reassignment': instance.pendingReassignment,
};
