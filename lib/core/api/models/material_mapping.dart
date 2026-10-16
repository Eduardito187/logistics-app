// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'material_mapping.g.dart';

@JsonSerializable()
class MaterialMapping {
  const MaterialMapping({
    required this.id,
    required this.sku,
    required this.material,
    required this.center,
    required this.warehouse,
  });

  factory MaterialMapping.fromJson(Map<String, Object?> json) =>
      _$MaterialMappingFromJson(json);

  final String id;
  final String sku;
  final String material;
  final String center;
  final String warehouse;

  Map<String, Object?> toJson() => _$MaterialMappingToJson(this);
}
