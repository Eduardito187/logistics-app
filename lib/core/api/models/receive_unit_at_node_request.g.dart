// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receive_unit_at_node_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiveUnitAtNodeRequest _$ReceiveUnitAtNodeRequestFromJson(
  Map<String, dynamic> json,
) => ReceiveUnitAtNodeRequest(
  shipmentId: json['shipment_id'] as String,
  unitId: json['unit_id'] as String,
  destinationNodeId: json['destination_node_id'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  location: json['location'] == null
      ? null
      : CapturedLocation.fromJson(json['location'] as Map<String, dynamic>),
  deviceId: json['device_id'] as String?,
  userId: json['user_id'] as String?,
  idempotencyKey: json['idempotency_key'] as String?,
);

Map<String, dynamic> _$ReceiveUnitAtNodeRequestToJson(
  ReceiveUnitAtNodeRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'unit_id': instance.unitId,
  'destination_node_id': instance.destinationNodeId,
  'lat': instance.lat,
  'lng': instance.lng,
  'location': instance.location,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'device_id': instance.deviceId,
  'user_id': instance.userId,
  'idempotency_key': instance.idempotencyKey,
};
