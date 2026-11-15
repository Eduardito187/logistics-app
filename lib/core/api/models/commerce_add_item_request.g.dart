// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_add_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceAddItemRequest _$CommerceAddItemRequestFromJson(
  Map<String, dynamic> json,
) => CommerceAddItemRequest(
  sku: json['sku'] as String,
  productName: json['product_name'] as String,
  unitPriceCents: (json['unit_price_cents'] as num).toInt(),
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$CommerceAddItemRequestToJson(
  CommerceAddItemRequest instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'product_name': instance.productName,
  'unit_price_cents': instance.unitPriceCents,
  'quantity': instance.quantity,
};
