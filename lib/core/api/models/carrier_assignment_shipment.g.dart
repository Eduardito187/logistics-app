// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_assignment_shipment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierAssignmentShipment _$CarrierAssignmentShipmentFromJson(
  Map<String, dynamic> json,
) => CarrierAssignmentShipment(
  shipmentId: json['shipment_id'] as String,
  externalId: json['external_id'] as String,
  orderReference: json['order_reference'] as String?,
  customerName: json['customer_name'] as String,
  destinationNode: json['destination_node'] as String?,
  destinationNodeId: json['destination_node_id'] as String?,
  unitsCount: (json['units_count'] as num).toInt(),
  units: (json['units'] as List<dynamic>)
      .map((e) => CarrierAssignmentUnit.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CarrierAssignmentShipmentToJson(
  CarrierAssignmentShipment instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'external_id': instance.externalId,
  'order_reference': instance.orderReference,
  'customer_name': instance.customerName,
  'destination_node': instance.destinationNode,
  'destination_node_id': instance.destinationNodeId,
  'units_count': instance.unitsCount,
  'units': instance.units,
};
