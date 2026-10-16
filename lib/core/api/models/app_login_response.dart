// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_device_payload.dart';
import 'app_user_profile.dart';

part 'app_login_response.g.dart';

@JsonSerializable()
class AppLoginResponse {
  const AppLoginResponse({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
    required this.device,
  });

  factory AppLoginResponse.fromJson(Map<String, Object?> json) =>
      _$AppLoginResponseFromJson(json);

  final String token;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  final AppUserProfile user;
  final AppDevicePayload device;

  Map<String, Object?> toJson() => _$AppLoginResponseToJson(this);
}
