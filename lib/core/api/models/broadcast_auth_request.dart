// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'broadcast_auth_request.g.dart';

@JsonSerializable()
class BroadcastAuthRequest {
  const BroadcastAuthRequest({
    required this.socketId,
    required this.channelName,
  });

  factory BroadcastAuthRequest.fromJson(Map<String, Object?> json) =>
      _$BroadcastAuthRequestFromJson(json);

  /// Id de socket que entrega el servidor al conectar, p. ej. 1234.5678
  @JsonKey(name: 'socket_id')
  final String socketId;

  /// Canal con prefijo, p. ej. private-user.42
  @JsonKey(name: 'channel_name')
  final String channelName;

  Map<String, Object?> toJson() => _$BroadcastAuthRequestToJson(this);
}
