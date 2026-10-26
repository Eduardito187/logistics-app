// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReturnOrder _$ReturnOrderFromJson(Map<String, dynamic> json) => ReturnOrder(
  id: json['id'] as String,
  originalReference: json['original_reference'] as String,
  sellerId: json['seller_id'] as String?,
  warehouseId: json['warehouse_id'] as String,
  fulfillmentMode: ReturnFulfillmentMode.fromJson(
    json['fulfillment_mode'] as String,
  ),
  kind: ReturnOrderKind.fromJson(json['kind'] as String),
  disposition: json['disposition'] == null
      ? null
      : ReturnDisposition.fromJson(json['disposition'] as String),
  status: ReturnOrderStatus.fromJson(json['status'] as String),
  lines: (json['lines'] as List<dynamic>)
      .map((e) => ReturnLine.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReturnOrderToJson(ReturnOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'original_reference': instance.originalReference,
      'seller_id': instance.sellerId,
      'warehouse_id': instance.warehouseId,
      'fulfillment_mode': instance.fulfillmentMode,
      'kind': instance.kind,
      'disposition': instance.disposition,
      'status': instance.status,
      'lines': instance.lines,
    };
