// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_order_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceOrderLine _$CommerceOrderLineFromJson(Map<String, dynamic> json) =>
    CommerceOrderLine(
      sku: json['sku'] as String,
      productName: json['product_name'] as String,
      unitPriceCents: (json['unit_price_cents'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$CommerceOrderLineToJson(CommerceOrderLine instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'product_name': instance.productName,
      'unit_price_cents': instance.unitPriceCents,
      'quantity': instance.quantity,
    };
