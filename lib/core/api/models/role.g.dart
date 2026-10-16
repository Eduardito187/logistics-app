// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Role _$RoleFromJson(Map<String, dynamic> json) => Role(
  id: json['id'] as String,
  key: json['key'] as String,
  name: json['name'] as String,
  isSystem: json['is_system'] as bool,
  permissionKeys: (json['permission_keys'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$RoleToJson(Role instance) => <String, dynamic>{
  'id': instance.id,
  'key': instance.key,
  'name': instance.name,
  'description': instance.description,
  'is_system': instance.isSystem,
  'permission_keys': instance.permissionKeys,
};
