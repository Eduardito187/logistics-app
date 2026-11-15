// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_search_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceSearchItem _$CommerceSearchItemFromJson(Map<String, dynamic> json) =>
    CommerceSearchItem(
      id: json['id'] as String,
      name: json['name'] as String,
      canonicalSku: json['canonical_sku'] as String,
      status: json['status'] as String,
      categoryId: json['category_id'] as String?,
    );

Map<String, dynamic> _$CommerceSearchItemToJson(CommerceSearchItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'canonical_sku': instance.canonicalSku,
      'category_id': instance.categoryId,
      'status': instance.status,
    };
