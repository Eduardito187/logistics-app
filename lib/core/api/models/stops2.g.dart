// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stops2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stops2 _$Stops2FromJson(Map<String, dynamic> json) => Stops2(
  shipmentId: json['shipment_id'] as String?,
  sequence: (json['sequence'] as num?)?.toInt(),
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  lat: json['lat'] as num?,
  lng: json['lng'] as num?,
  plannedEta: json['planned_eta'] == null
      ? null
      : DateTime.parse(json['planned_eta'] as String),
  eta: json['eta'] == null ? null : DateTime.parse(json['eta'] as String),
  remainingDistanceM: (json['remaining_distance_m'] as num?)?.toInt(),
  remainingDurationS: (json['remaining_duration_s'] as num?)?.toInt(),
  method: json['method'] == null
      ? null
      : Method.fromJson(json['method'] as String),
  computedAt: json['computed_at'] == null
      ? null
      : DateTime.parse(json['computed_at'] as String),
);

Map<String, dynamic> _$Stops2ToJson(Stops2 instance) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'sequence': instance.sequence,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
  'lat': instance.lat,
  'lng': instance.lng,
  'planned_eta': instance.plannedEta?.toIso8601String(),
  'eta': instance.eta?.toIso8601String(),
  'remaining_distance_m': instance.remainingDistanceM,
  'remaining_duration_s': instance.remainingDurationS,
  'method': instance.method,
  'computed_at': instance.computedAt?.toIso8601String(),
};
