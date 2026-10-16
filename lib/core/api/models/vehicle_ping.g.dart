// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_ping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehiclePing _$VehiclePingFromJson(Map<String, dynamic> json) => VehiclePing(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  recordedAt: DateTime.parse(json['recorded_at'] as String),
  speedKph: (json['speed_kph'] as num?)?.toDouble(),
  heading: (json['heading'] as num?)?.toInt(),
  accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
  ignition: json['ignition'] as bool?,
  odometerM: (json['odometer_m'] as num?)?.toInt(),
  deviceId: json['device_id'] as String?,
);

Map<String, dynamic> _$VehiclePingToJson(VehiclePing instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'recorded_at': instance.recordedAt.toIso8601String(),
      'speed_kph': instance.speedKph,
      'heading': instance.heading,
      'accuracy_m': instance.accuracyM,
      'ignition': instance.ignition,
      'odometer_m': instance.odometerM,
      'device_id': instance.deviceId,
    };
