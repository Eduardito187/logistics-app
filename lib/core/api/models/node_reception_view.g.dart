// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_reception_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeReceptionView _$NodeReceptionViewFromJson(Map<String, dynamic> json) =>
    NodeReceptionView(
      id: json['id'] as String,
      shipmentId: json['shipment_id'] as String,
      originNodeId: json['origin_node_id'] as String,
      destinationNodeId: json['destination_node_id'] as String,
      corridor: NodeReceptionViewCorridor.fromJson(json['corridor'] as String),
      status: NodeReceptionViewStatus.fromJson(json['status'] as String),
      expectedUnitIds: (json['expected_unit_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      receivedUnitIds: (json['received_unit_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      missingUnitIds: (json['missing_unit_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      surplusUnitIds: (json['surplus_unit_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      expectedCount: (json['expected_count'] as num).toInt(),
      receivedCount: (json['received_count'] as num).toInt(),
      complete: json['complete'] as bool,
      openedAt: DateTime.parse(json['opened_at'] as String),
      reconciledAt: json['reconciled_at'] == null
          ? null
          : DateTime.parse(json['reconciled_at'] as String),
    );

Map<String, dynamic> _$NodeReceptionViewToJson(NodeReceptionView instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shipment_id': instance.shipmentId,
      'origin_node_id': instance.originNodeId,
      'destination_node_id': instance.destinationNodeId,
      'corridor': instance.corridor,
      'status': instance.status,
      'expected_unit_ids': instance.expectedUnitIds,
      'received_unit_ids': instance.receivedUnitIds,
      'missing_unit_ids': instance.missingUnitIds,
      'surplus_unit_ids': instance.surplusUnitIds,
      'expected_count': instance.expectedCount,
      'received_count': instance.receivedCount,
      'complete': instance.complete,
      'opened_at': instance.openedAt.toIso8601String(),
      'reconciled_at': instance.reconciledAt?.toIso8601String(),
    };
