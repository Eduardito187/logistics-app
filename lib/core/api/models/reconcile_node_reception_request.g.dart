// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconcile_node_reception_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReconcileNodeReceptionRequest _$ReconcileNodeReceptionRequestFromJson(
  Map<String, dynamic> json,
) => ReconcileNodeReceptionRequest(
  shipmentId: json['shipment_id'] as String,
  destinationNodeId: json['destination_node_id'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  deviceId: json['device_id'] as String?,
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$ReconcileNodeReceptionRequestToJson(
  ReconcileNodeReceptionRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'destination_node_id': instance.destinationNodeId,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'device_id': instance.deviceId,
  'user_id': instance.userId,
};
