// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_product_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceProductVariant _$CommerceProductVariantFromJson(
  Map<String, dynamic> json,
) => CommerceProductVariant(
  sku: json['sku'] as String,
  name: json['name'] as String,
  attributes: Map<String, String>.from(json['attributes'] as Map),
);

Map<String, dynamic> _$CommerceProductVariantToJson(
  CommerceProductVariant instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'name': instance.name,
  'attributes': instance.attributes,
};
