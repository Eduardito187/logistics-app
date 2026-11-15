// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BroadcastAuthResponse _$BroadcastAuthResponseFromJson(
  Map<String, dynamic> json,
) => BroadcastAuthResponse(
  auth: json['auth'] as String,
  channelData: json['channel_data'] as String?,
);

Map<String, dynamic> _$BroadcastAuthResponseToJson(
  BroadcastAuthResponse instance,
) => <String, dynamic>{
  'auth': instance.auth,
  'channel_data': instance.channelData,
};
