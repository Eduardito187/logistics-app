// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_lookup_tracking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLookupTracking _$OrderLookupTrackingFromJson(Map<String, dynamic> json) =>
    OrderLookupTracking(
      stage: OrderLookupStage.fromJson(json['stage'] as String),
      stopsBefore: (json['stops_before'] as num?)?.toInt(),
      etaAt: json['eta_at'] == null
          ? null
          : DateTime.parse(json['eta_at'] as String),
      vehiclePlate: json['vehicle_plate'] as String?,
      currentNode: json['current_node'] == null
          ? null
          : OrderLookupNodeRef.fromJson(
              json['current_node'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OrderLookupTrackingToJson(
  OrderLookupTracking instance,
) => <String, dynamic>{
  'stage': instance.stage,
  'stops_before': instance.stopsBefore,
  'eta_at': instance.etaAt?.toIso8601String(),
  'vehicle_plate': instance.vehiclePlate,
  'current_node': instance.currentNode,
};
