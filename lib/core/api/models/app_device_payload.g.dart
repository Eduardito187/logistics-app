// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_device_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppDevicePayload _$AppDevicePayloadFromJson(Map<String, dynamic> json) =>
    AppDevicePayload(
      uuid: json['uuid'] as String,
      platform: json['platform'] as String?,
      name: json['name'] as String?,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
    );

Map<String, dynamic> _$AppDevicePayloadToJson(AppDevicePayload instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'platform': instance.platform,
      'name': instance.name,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
    };
