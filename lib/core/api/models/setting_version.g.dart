// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingVersion _$SettingVersionFromJson(Map<String, dynamic> json) =>
    SettingVersion(
      id: json['id'] as String,
      key: json['key'] as String,
      version: (json['version'] as num).toInt(),
      value: json['value'],
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );

Map<String, dynamic> _$SettingVersionToJson(SettingVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'version': instance.version,
      'value': instance.value,
      'effective_from': instance.effectiveFrom.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'created_by': instance.createdBy,
    };
