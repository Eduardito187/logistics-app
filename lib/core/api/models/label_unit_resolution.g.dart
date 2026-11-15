// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_unit_resolution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabelUnitResolution _$LabelUnitResolutionFromJson(Map<String, dynamic> json) =>
    LabelUnitResolution(
      labelId: json['label_id'] as String,
      resolved: json['resolved'] as bool,
      unitId: json['unit_id'] as String?,
      shipmentId: json['shipment_id'] as String?,
      sku: json['sku'] as String?,
      productName: json['product_name'] as String?,
      lineNumber: (json['line_number'] as num?)?.toInt(),
      unit: json['unit'] == null
          ? null
          : Unit2.fromJson(json['unit'] as Map<String, dynamic>),
      piece: json['piece'] == null
          ? null
          : Piece2.fromJson(json['piece'] as Map<String, dynamic>),
      orderNumber: json['order_number'] as String?,
      customerName: json['customer_name'] as String?,
      customerDocumentId: json['customer_document_id'] as String?,
      customerPhone: json['customer_phone'] as String?,
      destinationNodeId: json['destination_node_id'] as String?,
    );

Map<String, dynamic> _$LabelUnitResolutionToJson(
  LabelUnitResolution instance,
) => <String, dynamic>{
  'label_id': instance.labelId,
  'resolved': instance.resolved,
  'unit_id': instance.unitId,
  'shipment_id': instance.shipmentId,
  'sku': instance.sku,
  'product_name': instance.productName,
  'line_number': instance.lineNumber,
  'unit': instance.unit,
  'piece': instance.piece,
  'order_number': instance.orderNumber,
  'customer_name': instance.customerName,
  'customer_document_id': instance.customerDocumentId,
  'customer_phone': instance.customerPhone,
  'destination_node_id': instance.destinationNodeId,
};
