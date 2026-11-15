// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCategory _$CommerceCategoryFromJson(Map<String, dynamic> json) =>
    CommerceCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      parentId: json['parent_id'] as String?,
    );

Map<String, dynamic> _$CommerceCategoryToJson(CommerceCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'parent_id': instance.parentId,
    };
