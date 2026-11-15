// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'material_mapping.dart';
import 'meta6.dart';

part 'material_mapping_collection.g.dart';

@JsonSerializable()
class MaterialMappingCollection {
  const MaterialMappingCollection({required this.data, required this.meta});

  factory MaterialMappingCollection.fromJson(Map<String, Object?> json) =>
      _$MaterialMappingCollectionFromJson(json);

  final List<MaterialMapping> data;
  final Meta6 meta;

  Map<String, Object?> toJson() => _$MaterialMappingCollectionToJson(this);
}
