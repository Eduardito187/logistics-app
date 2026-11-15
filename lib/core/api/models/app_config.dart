// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_config_data.dart';

part 'app_config.g.dart';

@JsonSerializable()
class AppConfig {
  const AppConfig({required this.data});

  factory AppConfig.fromJson(Map<String, Object?> json) =>
      _$AppConfigFromJson(json);

  final AppConfigData data;

  Map<String, Object?> toJson() => _$AppConfigToJson(this);
}
