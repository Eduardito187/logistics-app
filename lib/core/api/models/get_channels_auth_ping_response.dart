// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_channels_auth_ping_response.g.dart';

@JsonSerializable()
class GetChannelsAuthPingResponse {
  const GetChannelsAuthPingResponse({required this.status, this.channel});

  factory GetChannelsAuthPingResponse.fromJson(Map<String, Object?> json) =>
      _$GetChannelsAuthPingResponseFromJson(json);

  final String status;
  final String? channel;

  Map<String, Object?> toJson() => _$GetChannelsAuthPingResponseToJson(this);
}
