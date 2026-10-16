// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'define_material_mapping_request.dart';
import 'meta2.dart';

part 'post_app_sap_material_mappings_response.g.dart';

@JsonSerializable()
class PostAppSapMaterialMappingsResponse {
  const PostAppSapMaterialMappingsResponse({
    required this.data,
    required this.meta,
  });

  factory PostAppSapMaterialMappingsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostAppSapMaterialMappingsResponseFromJson(json);

  final DefineMaterialMappingRequest data;
  final Meta2 meta;

  Map<String, Object?> toJson() =>
      _$PostAppSapMaterialMappingsResponseToJson(this);
}
