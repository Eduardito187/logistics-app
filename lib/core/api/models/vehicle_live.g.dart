// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_live.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleLive _$VehicleLiveFromJson(Map<String, dynamic> json) => VehicleLive(
  vehicleId: json['vehicle_id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  moving: json['moving'] as bool,
  recordedAt: DateTime.parse(json['recorded_at'] as String),
  speedKph: (json['speed_kph'] as num?)?.toDouble(),
  heading: (json['heading'] as num?)?.toInt(),
  ignition: json['ignition'] as bool?,
  routeId: json['route_id'] as String?,
);

Map<String, dynamic> _$VehicleLiveToJson(VehicleLive instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'lat': instance.lat,
      'lng': instance.lng,
      'speed_kph': instance.speedKph,
      'heading': instance.heading,
      'ignition': instance.ignition,
      'moving': instance.moving,
      'route_id': instance.routeId,
      'recorded_at': instance.recordedAt.toIso8601String(),
    };
