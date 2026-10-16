// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data11.dart';

part 'get_channels_tracking_token_units_response.g.dart';

@JsonSerializable()
class GetChannelsTrackingTokenUnitsResponse {
  const GetChannelsTrackingTokenUnitsResponse({required this.data});

  factory GetChannelsTrackingTokenUnitsResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetChannelsTrackingTokenUnitsResponseFromJson(json);

  final Data11 data;

  Map<String, Object?> toJson() =>
      _$GetChannelsTrackingTokenUnitsResponseToJson(this);
}
