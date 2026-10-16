// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'public_tracking.dart';

part 'get_channels_tracking_token_response.g.dart';

@JsonSerializable()
class GetChannelsTrackingTokenResponse {
  const GetChannelsTrackingTokenResponse({required this.data});

  factory GetChannelsTrackingTokenResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsTrackingTokenResponseFromJson(json);

  final PublicTracking data;

  Map<String, Object?> toJson() =>
      _$GetChannelsTrackingTokenResponseToJson(this);
}
