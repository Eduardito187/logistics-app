// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'define_material_mapping_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DefineMaterialMappingRequest _$DefineMaterialMappingRequestFromJson(
  Map<String, dynamic> json,
) => DefineMaterialMappingRequest(
  sku: json['sku'] as String,
  material: json['material'] as String,
  center: json['center'] as String,
  warehouse: json['warehouse'] as String,
);

Map<String, dynamic> _$DefineMaterialMappingRequestToJson(
  DefineMaterialMappingRequest instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'material': instance.material,
  'center': instance.center,
  'warehouse': instance.warehouse,
};
