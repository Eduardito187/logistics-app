// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_config_field.dart';
import 'app_config_map.dart';
import 'app_config_support.dart';
import 'app_config_version.dart';

part 'app_config_data.g.dart';

@JsonSerializable()
class AppConfigData {
  const AppConfigData({
    required this.version,
    required this.featureFlags,
    required this.map,
    required this.support,
    required this.polling,
    required this.field,
    this.platform,
  });

  factory AppConfigData.fromJson(Map<String, Object?> json) =>
      _$AppConfigDataFromJson(json);

  final String? platform;
  final AppConfigVersion version;
  @JsonKey(name: 'feature_flags')
  final Map<String, bool> featureFlags;
  final AppConfigMap map;
  final AppConfigSupport support;

  /// Polling intervals in seconds (notifications_seconds, tasks_seconds, location_seconds, outbox_drain_seconds, app_config_seconds).
  final Map<String, int> polling;
  final AppConfigField field;

  Map<String, Object?> toJson() => _$AppConfigDataToJson(this);
}
