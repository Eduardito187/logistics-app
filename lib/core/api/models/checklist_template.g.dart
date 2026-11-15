// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistTemplate _$ChecklistTemplateFromJson(Map<String, dynamic> json) =>
    ChecklistTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      vehicleType: json['vehicle_type'] as String?,
      active: json['active'] as bool,
      items: (json['items'] as List<dynamic>)
          .map((e) => ChecklistTemplateItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      criticalKeys: (json['critical_keys'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ChecklistTemplateToJson(ChecklistTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'vehicle_type': instance.vehicleType,
      'active': instance.active,
      'items': instance.items,
      'critical_keys': instance.criticalKeys,
    };
