// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
  fingerprint: json['fingerprint'] as String,
  platform: json['platform'] as String?,
  clientKind: json['client_kind'] == null
      ? null
      : ClientKind.fromJson(json['client_kind'] as String?),
  name: json['name'] as String?,
  pushToken: json['push_token'] as String?,
);

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
  'fingerprint': instance.fingerprint,
  'platform': instance.platform,
  'client_kind': instance.clientKind,
  'name': instance.name,
  'push_token': instance.pushToken,
};
