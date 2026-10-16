// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicTracking _$PublicTrackingFromJson(Map<String, dynamic> json) =>
    PublicTracking(
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
      stopsMessage: json['stops_message'] as String,
    );

Map<String, dynamic> _$PublicTrackingToJson(PublicTracking instance) =>
    <String, dynamic>{
      'status': instance.status,
      'remaining_stops': instance.remainingStops,
      'route_position': instance.routePosition,
      'eta': instance.eta?.toIso8601String(),
      'last_position': instance.lastPosition,
      'position_is_live': instance.positionIsLive,
      'stops_message': instance.stopsMessage,
    };
