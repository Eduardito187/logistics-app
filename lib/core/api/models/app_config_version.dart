// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_config_version.g.dart';

@JsonSerializable()
class AppConfigVersion {
  const AppConfigVersion({
    required this.enforced,
    this.minAppVersion,
    this.latestAppVersion,
    this.updateUrl,
    this.minAppVersions,
  });

  factory AppConfigVersion.fromJson(Map<String, Object?> json) =>
      _$AppConfigVersionFromJson(json);

  @JsonKey(name: 'min_app_version')
  final String? minAppVersion;
  @JsonKey(name: 'latest_app_version')
  final String? latestAppVersion;
  @JsonKey(name: 'update_url')
  final String? updateUrl;
  final bool enforced;
  @JsonKey(name: 'min_app_versions')
  final Map<String, String?>? minAppVersions;

  Map<String, Object?> toJson() => _$AppConfigVersionToJson(this);
}
