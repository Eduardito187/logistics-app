// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_category.g.dart';

@JsonSerializable()
class CommerceCategory {
  const CommerceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });

  factory CommerceCategory.fromJson(Map<String, Object?> json) =>
      _$CommerceCategoryFromJson(json);

  final String id;
  final String name;
  final String slug;
  @JsonKey(name: 'parent_id')
  final String? parentId;

  Map<String, Object?> toJson() => _$CommerceCategoryToJson(this);
}
