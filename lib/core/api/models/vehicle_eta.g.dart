// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_eta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleEta _$VehicleEtaFromJson(Map<String, dynamic> json) => VehicleEta(
  offRoute: json['off_route'] as bool?,
  offRouteSince: json['off_route_since'] == null
      ? null
      : DateTime.parse(json['off_route_since'] as String),
  rerouteGeometry: (json['reroute_geometry'] as List<dynamic>?)
      ?.map((e) => LatLngPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
  shipmentId: json['shipment_id'] as String?,
  vehicleId: json['vehicle_id'] as String?,
  plate: json['plate'] as String?,
  trafficAware: json['traffic_aware'] as bool?,
  position: json['position'] == null
      ? null
      : Position.fromJson(json['position'] as Map<String, dynamic>),
  positionStale: json['position_stale'] as bool?,
  generatedAt: json['generated_at'] == null
      ? null
      : DateTime.parse(json['generated_at'] as String),
  stops: (json['stops'] as List<dynamic>?)
      ?.map((e) => Stops2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$VehicleEtaToJson(VehicleEta instance) =>
    <String, dynamic>{
      'off_route': instance.offRoute,
      'off_route_since': instance.offRouteSince?.toIso8601String(),
      'reroute_geometry': instance.rerouteGeometry,
      'shipment_id': instance.shipmentId,
      'vehicle_id': instance.vehicleId,
      'plate': instance.plate,
      'traffic_aware': instance.trafficAware,
      'position': instance.position,
      'position_stale': instance.positionStale,
      'generated_at': instance.generatedAt?.toIso8601String(),
      'stops': instance.stops,
    };
