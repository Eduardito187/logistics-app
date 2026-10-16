// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_mapping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialMapping _$MaterialMappingFromJson(Map<String, dynamic> json) =>
    MaterialMapping(
      id: json['id'] as String,
      sku: json['sku'] as String,
      material: json['material'] as String,
      center: json['center'] as String,
      warehouse: json['warehouse'] as String,
    );

Map<String, dynamic> _$MaterialMappingToJson(MaterialMapping instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sku': instance.sku,
      'material': instance.material,
      'center': instance.center,
      'warehouse': instance.warehouse,
    };
