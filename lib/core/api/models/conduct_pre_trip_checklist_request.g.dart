// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conduct_pre_trip_checklist_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConductPreTripChecklistRequest _$ConductPreTripChecklistRequestFromJson(
  Map<String, dynamic> json,
) => ConductPreTripChecklistRequest(
  vehicleId: json['vehicle_id'] as String,
  driverId: json['driver_id'] as String,
  items: Map<String, bool>.from(json['items'] as Map),
  performedOn: DateTime.parse(json['performed_on'] as String),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ConductPreTripChecklistRequestToJson(
  ConductPreTripChecklistRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'items': instance.items,
  'performed_on': instance.performedOn.toIso8601String(),
  'notes': instance.notes,
};
