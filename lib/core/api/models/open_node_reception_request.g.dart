// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_node_reception_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenNodeReceptionRequest _$OpenNodeReceptionRequestFromJson(
  Map<String, dynamic> json,
) => OpenNodeReceptionRequest(
  shipmentId: json['shipment_id'] as String,
  originNodeId: json['origin_node_id'] as String,
  destinationNodeId: json['destination_node_id'] as String,
  originNodeKind: OpenNodeReceptionRequestOriginNodeKind.fromJson(
    json['origin_node_kind'] as String,
  ),
  destinationNodeKind: OpenNodeReceptionRequestDestinationNodeKind.fromJson(
    json['destination_node_kind'] as String,
  ),
  expectedUnitIds: (json['expected_unit_ids'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
);

Map<String, dynamic> _$OpenNodeReceptionRequestToJson(
  OpenNodeReceptionRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'origin_node_id': instance.originNodeId,
  'destination_node_id': instance.destinationNodeId,
  'origin_node_kind': instance.originNodeKind,
  'destination_node_kind': instance.destinationNodeKind,
  'expected_unit_ids': instance.expectedUnitIds,
  'occurred_at': instance.occurredAt.toIso8601String(),
};
