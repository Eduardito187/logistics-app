// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BroadcastConfig _$BroadcastConfigFromJson(Map<String, dynamic> json) =>
    BroadcastConfig(
      enabled: json['enabled'] as bool,
      key: json['key'] as String?,
      cluster: json['cluster'] as String?,
      path: json['path'] as String,
      channels: (json['channels'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
    );

Map<String, dynamic> _$BroadcastConfigToJson(BroadcastConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'key': instance.key,
      'cluster': instance.cluster,
      'path': instance.path,
      'channels': instance.channels,
    };
