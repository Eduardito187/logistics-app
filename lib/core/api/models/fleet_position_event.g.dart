// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_position_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FleetPositionEvent _$FleetPositionEventFromJson(Map<String, dynamic> json) =>
    FleetPositionEvent(
      vehicleId: json['vehicle_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      moving: json['moving'] as bool,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      plate: json['plate'] as String?,
      driverId: json['driver_id'] as String?,
      baseNodeId: json['base_node_id'] as String?,
      baseNodeName: json['base_node_name'] as String?,
      city: json['city'] as String?,
      driverName: json['driver_name'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      speedKph: (json['speed_kph'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toInt(),
      ignition: json['ignition'] as bool?,
      routeId: json['route_id'] as String?,
    );

Map<String, dynamic> _$FleetPositionEventToJson(FleetPositionEvent instance) =>
    <String, dynamic>{
      'plate': instance.plate,
      'driver_id': instance.driverId,
      'base_node_id': instance.baseNodeId,
      'base_node_name': instance.baseNodeName,
      'city': instance.city,
      'driver_name': instance.driverName,
      'updated_at': instance.updatedAt?.toIso8601String(),
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
