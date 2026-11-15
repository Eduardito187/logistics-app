// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devices.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Devices _$DevicesFromJson(Map<String, dynamic> json) => Devices(
  id: json['id'] as String?,
  name: json['name'] as String?,
  platform: json['platform'] as String?,
  model: json['model'] as String?,
  osVersion: json['os_version'] as String?,
  appVersion: json['app_version'] as String?,
  sessionBucket: json['session_bucket'] as String?,
  lastSeenAt: json['last_seen_at'] == null
      ? null
      : DateTime.parse(json['last_seen_at'] as String),
  revoked: json['revoked'] as bool?,
);

Map<String, dynamic> _$DevicesToJson(Devices instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'platform': instance.platform,
  'model': instance.model,
  'os_version': instance.osVersion,
  'app_version': instance.appVersion,
  'session_bucket': instance.sessionBucket,
  'last_seen_at': instance.lastSeenAt?.toIso8601String(),
  'revoked': instance.revoked,
};
