// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigData _$AppConfigDataFromJson(
  Map<String, dynamic> json,
) => AppConfigData(
  version: AppConfigVersion.fromJson(json['version'] as Map<String, dynamic>),
  featureFlags: Map<String, bool>.from(json['feature_flags'] as Map),
  map: AppConfigMap.fromJson(json['map'] as Map<String, dynamic>),
  support: AppConfigSupport.fromJson(json['support'] as Map<String, dynamic>),
  polling: Map<String, int>.from(json['polling'] as Map),
  field: AppConfigField.fromJson(json['field'] as Map<String, dynamic>),
  platform: json['platform'] as String?,
);

Map<String, dynamic> _$AppConfigDataToJson(AppConfigData instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'version': instance.version,
      'feature_flags': instance.featureFlags,
      'map': instance.map,
      'support': instance.support,
      'polling': instance.polling,
      'field': instance.field,
    };
