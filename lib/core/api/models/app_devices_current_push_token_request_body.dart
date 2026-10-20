// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_devices_current_push_token_request_body.g.dart';

@JsonSerializable()
class AppDevicesCurrentPushTokenRequestBody {
  const AppDevicesCurrentPushTokenRequestBody({required this.pushToken});

  factory AppDevicesCurrentPushTokenRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppDevicesCurrentPushTokenRequestBodyFromJson(json);

  /// Firebase Installation ID, or null to opt out of push.
  @JsonKey(name: 'push_token')
  final String? pushToken;

  Map<String, Object?> toJson() =>
      _$AppDevicesCurrentPushTokenRequestBodyToJson(this);
}
