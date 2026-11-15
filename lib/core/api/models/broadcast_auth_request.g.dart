// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_auth_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BroadcastAuthRequest _$BroadcastAuthRequestFromJson(
  Map<String, dynamic> json,
) => BroadcastAuthRequest(
  socketId: json['socket_id'] as String,
  channelName: json['channel_name'] as String,
);

Map<String, dynamic> _$BroadcastAuthRequestToJson(
  BroadcastAuthRequest instance,
) => <String, dynamic>{
  'socket_id': instance.socketId,
  'channel_name': instance.channelName,
};
