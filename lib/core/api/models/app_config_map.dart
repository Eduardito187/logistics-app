// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_config_map.g.dart';

@JsonSerializable()
class AppConfigMap {
  const AppConfigMap({
    required this.tileUrl,
    required this.attribution,
    required this.maxZoom,
  });

  factory AppConfigMap.fromJson(Map<String, Object?> json) =>
      _$AppConfigMapFromJson(json);

  @JsonKey(name: 'tile_url')
  final String tileUrl;
  final String attribution;
  @JsonKey(name: 'max_zoom')
  final int maxZoom;

  Map<String, Object?> toJson() => _$AppConfigMapToJson(this);
}
