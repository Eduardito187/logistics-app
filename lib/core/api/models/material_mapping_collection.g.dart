// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_mapping_collection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialMappingCollection _$MaterialMappingCollectionFromJson(
  Map<String, dynamic> json,
) => MaterialMappingCollection(
  data: (json['data'] as List<dynamic>)
      .map((e) => MaterialMapping.fromJson(e as Map<String, dynamic>))
      .toList(),
  meta: Meta12.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MaterialMappingCollectionToJson(
  MaterialMappingCollection instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
