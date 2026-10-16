// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_app_sap_material_mappings_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostAppSapMaterialMappingsResponse _$PostAppSapMaterialMappingsResponseFromJson(
  Map<String, dynamic> json,
) => PostAppSapMaterialMappingsResponse(
  data: DefineMaterialMappingRequest.fromJson(
    json['data'] as Map<String, dynamic>,
  ),
  meta: Meta2.fromJson(json['meta'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PostAppSapMaterialMappingsResponseToJson(
  PostAppSapMaterialMappingsResponse instance,
) => <String, dynamic>{'data': instance.data, 'meta': instance.meta};
