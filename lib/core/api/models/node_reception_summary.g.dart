// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node_reception_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NodeReceptionSummary _$NodeReceptionSummaryFromJson(
  Map<String, dynamic> json,
) => NodeReceptionSummary(
  id: json['id'] as String?,
  shipmentId: json['shipment_id'] as String?,
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String?,
  originNodeId: json['origin_node_id'] as String?,
  destinationNodeId: json['destination_node_id'] as String?,
  corridor: json['corridor'] as String?,
  reception: json['reception'] == null
      ? null
      : Reception.fromJson(json['reception'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NodeReceptionSummaryToJson(
  NodeReceptionSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'shipment_id': instance.shipmentId,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
  'origin_node_id': instance.originNodeId,
  'destination_node_id': instance.destinationNodeId,
  'corridor': instance.corridor,
  'reception': instance.reception,
};
