// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_template_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistTemplateItem _$ChecklistTemplateItemFromJson(
  Map<String, dynamic> json,
) => ChecklistTemplateItem(
  key: json['key'] as String,
  label: json['label'] as String,
  category: ChecklistTemplateItemCategory.fromJson(json['category'] as String),
  criticality: ChecklistTemplateItemCriticality.fromJson(
    json['criticality'] as String,
  ),
  requiresPhoto: json['requires_photo'] as bool,
  position: (json['position'] as num).toInt(),
);

Map<String, dynamic> _$ChecklistTemplateItemToJson(
  ChecklistTemplateItem instance,
) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'category': instance.category,
  'criticality': instance.criticality,
  'requires_photo': instance.requiresPhoto,
  'position': instance.position,
};
