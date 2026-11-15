// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config_map.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfigMap _$AppConfigMapFromJson(Map<String, dynamic> json) => AppConfigMap(
  tileUrl: json['tile_url'] as String,
  attribution: json['attribution'] as String,
  maxZoom: (json['max_zoom'] as num).toInt(),
);

Map<String, dynamic> _$AppConfigMapToJson(AppConfigMap instance) =>
    <String, dynamic>{
      'tile_url': instance.tileUrl,
      'attribution': instance.attribution,
      'max_zoom': instance.maxZoom,
    };
