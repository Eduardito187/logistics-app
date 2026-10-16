// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceListItem _$DeviceListItemFromJson(Map<String, dynamic> json) =>
    DeviceListItem(
      uuid: json['uuid'] as String,
      platform: json['platform'] as String?,
      name: json['name'] as String?,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      revoked: json['revoked'] as bool,
    );

Map<String, dynamic> _$DeviceListItemToJson(DeviceListItem instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'platform': instance.platform,
      'name': instance.name,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'revoked': instance.revoked,
    };
