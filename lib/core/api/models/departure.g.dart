// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'departure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Departure _$DepartureFromJson(Map<String, dynamic> json) => Departure(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  helperIds: (json['helper_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  load: Load.fromJson(json['load'] as Map<String, dynamic>),
  status: DepartureStatus.fromJson(json['status'] as String),
  departedAt: DateTime.parse(json['departed_at'] as String),
  driverId: json['driver_id'] as String?,
  destination: json['destination'] as String?,
  routeRef: json['route_ref'] as String?,
  odometerOutKm: (json['odometer_out_km'] as num?)?.toInt(),
  odometerInKm: (json['odometer_in_km'] as num?)?.toInt(),
  kmTraveled: (json['km_traveled'] as num?)?.toInt(),
  returnedAt: json['returned_at'] == null
      ? null
      : DateTime.parse(json['returned_at'] as String),
  note: json['note'] as String?,
);

Map<String, dynamic> _$DepartureToJson(Departure instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'helper_ids': instance.helperIds,
  'destination': instance.destination,
  'route_ref': instance.routeRef,
  'load': instance.load,
  'odometer_out_km': instance.odometerOutKm,
  'odometer_in_km': instance.odometerInKm,
  'km_traveled': instance.kmTraveled,
  'status': instance.status,
  'departed_at': instance.departedAt.toIso8601String(),
  'returned_at': instance.returnedAt?.toIso8601String(),
  'note': instance.note,
};
