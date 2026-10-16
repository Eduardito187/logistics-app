// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Permission _$PermissionFromJson(Map<String, dynamic> json) => Permission(
  id: json['id'] as String,
  key: json['key'] as String,
  group: json['group'] as String,
  action: json['action'] as String,
  isSystem: json['is_system'] as bool,
  description: json['description'] as String?,
);

Map<String, dynamic> _$PermissionToJson(Permission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'group': instance.group,
      'action': instance.action,
      'description': instance.description,
      'is_system': instance.isSystem,
    };
