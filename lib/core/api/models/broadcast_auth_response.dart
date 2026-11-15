// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'broadcast_auth_response.g.dart';

@JsonSerializable()
class BroadcastAuthResponse {
  const BroadcastAuthResponse({required this.auth, this.channelData});

  factory BroadcastAuthResponse.fromJson(Map<String, Object?> json) =>
      _$BroadcastAuthResponseFromJson(json);

  /// <app_key>:<firma HMAC-SHA256>
  final String auth;

  /// Solo en canales de presencia
  @JsonKey(name: 'channel_data')
  final String? channelData;

  Map<String, Object?> toJson() => _$BroadcastAuthResponseToJson(this);
}
