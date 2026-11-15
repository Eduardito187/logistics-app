// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceProduct _$CommerceProductFromJson(Map<String, dynamic> json) =>
    CommerceProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      canonicalSku: json['canonical_sku'] as String,
      status: CommerceProductStatus.fromJson(json['status'] as String),
      variants: (json['variants'] as List<dynamic>)
          .map(
            (e) => CommerceProductVariant.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      media: (json['media'] as List<dynamic>)
          .map((e) => CommerceProductMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      physicalSpec: json['physical_spec'] == null
          ? null
          : ProductPhysicalSpec.fromJson(
              json['physical_spec'] as Map<String, dynamic>,
            ),
      sellerId: json['seller_id'] as String?,
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CommerceProductToJson(CommerceProduct instance) =>
    <String, dynamic>{
      'physical_spec': instance.physicalSpec,
      'id': instance.id,
      'seller_id': instance.sellerId,
      'category_id': instance.categoryId,
      'name': instance.name,
      'description': instance.description,
      'canonical_sku': instance.canonicalSku,
      'status': instance.status,
      'variants': instance.variants,
      'media': instance.media,
    };
