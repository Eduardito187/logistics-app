// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigVersion _$AppConfigVersionFromJson(Map<String, dynamic> json) =>
    AppConfigVersion(
      enforced: json['enforced'] as bool,
      minAppVersion: json['min_app_version'] as String?,
      latestAppVersion: json['latest_app_version'] as String?,
      updateUrl: json['update_url'] as String?,
      minAppVersions: (json['min_app_versions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String?),
      ),
    );

Map<String, dynamic> _$AppConfigVersionToJson(AppConfigVersion instance) =>
    <String, dynamic>{
      'min_app_version': instance.minAppVersion,
      'latest_app_version': instance.latestAppVersion,
      'update_url': instance.updateUrl,
      'enforced': instance.enforced,
      'min_app_versions': instance.minAppVersions,
    };
