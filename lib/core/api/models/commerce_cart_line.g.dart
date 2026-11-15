// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_cart_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCartLine _$CommerceCartLineFromJson(Map<String, dynamic> json) =>
    CommerceCartLine(
      sku: json['sku'] as String,
      productName: json['product_name'] as String,
      unitPriceCents: (json['unit_price_cents'] as num).toInt(),
      qty: (json['qty'] as num).toInt(),
      subtotalCents: (json['subtotal_cents'] as num).toInt(),
    );

Map<String, dynamic> _$CommerceCartLineToJson(CommerceCartLine instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'product_name': instance.productName,
      'unit_price_cents': instance.unitPriceCents,
      'qty': instance.qty,
      'subtotal_cents': instance.subtotalCents,
    };
