// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'checklist_template_item_category.dart';
import 'checklist_template_item_criticality.dart';

part 'checklist_template_item.g.dart';

@JsonSerializable()
class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.key,
    required this.label,
    required this.category,
    required this.criticality,
    required this.requiresPhoto,
    required this.position,
  });

  factory ChecklistTemplateItem.fromJson(Map<String, Object?> json) =>
      _$ChecklistTemplateItemFromJson(json);

  /// Stable key sent back in the checklist POST items map
  final String key;
  final String label;
  final ChecklistTemplateItemCategory category;
  final ChecklistTemplateItemCriticality criticality;
  @JsonKey(name: 'requires_photo')
  final bool requiresPhoto;
  final int position;

  Map<String, Object?> toJson() => _$ChecklistTemplateItemToJson(this);
}
