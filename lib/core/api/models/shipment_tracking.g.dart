// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentTracking _$ShipmentTrackingFromJson(Map<String, dynamic> json) =>
    ShipmentTracking(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      token: json['token'] as String,
      status: VisibleStatus.fromJson(json['status'] as String),
      remainingStops: (json['remaining_stops'] as num).toInt(),
      routePosition: (json['route_position'] as num?)?.toInt(),
      eta: json['eta'] == null ? null : DateTime.parse(json['eta'] as String),
      lastPosition: json['last_position'] == null
          ? null
          : TruckPosition.fromJson(
              json['last_position'] as Map<String, dynamic>,
            ),
      positionIsLive: json['position_is_live'] as bool?,
      shipmentExternalId: json['shipment_external_id'] as String?,
    );

Map<String, dynamic> _$ShipmentTrackingToJson(ShipmentTracking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'shipment_external_id': instance.shipmentExternalId,
      'token': instance.token,
      'status': instance.status,
      'remaining_stops': instance.remainingStops,
      'route_position': instance.routePosition,
      'eta': instance.eta?.toIso8601String(),
      'last_position': instance.lastPosition,
      'position_is_live': instance.positionIsLive,
    };
