// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_departure_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDepartureRequest _$RegisterDepartureRequestFromJson(
  Map<String, dynamic> json,
) => RegisterDepartureRequest(
  vehicleId: json['vehicle_id'] as String,
  departedAt: DateTime.parse(json['departed_at'] as String),
  driverId: json['driver_id'] as String?,
  helperIds: (json['helper_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  destination: json['destination'] as String?,
  routeRef: json['route_ref'] as String?,
  load: json['load'] == null
      ? null
      : Load2.fromJson(json['load'] as Map<String, dynamic>),
  odometerOutKm: (json['odometer_out_km'] as num?)?.toInt(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$RegisterDepartureRequestToJson(
  RegisterDepartureRequest instance,
) => <String, dynamic>{
  'vehicle_id': instance.vehicleId,
  'driver_id': instance.driverId,
  'helper_ids': instance.helperIds,
  'destination': instance.destination,
  'route_ref': instance.routeRef,
  'load': instance.load,
  'odometer_out_km': instance.odometerOutKm,
  'departed_at': instance.departedAt.toIso8601String(),
  'note': instance.note,
};
