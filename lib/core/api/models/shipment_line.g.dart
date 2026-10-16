// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipment_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShipmentLine _$ShipmentLineFromJson(Map<String, dynamic> json) => ShipmentLine(
  id: json['id'] as String,
  sku: json['sku'] as String,
  productName: json['product_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$ShipmentLineToJson(ShipmentLine instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'product_name': instance.productName,
      'quantity': instance.quantity,
    };
