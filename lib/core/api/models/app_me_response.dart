// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'app_device_payload.dart';
import 'app_user_profile.dart';

part 'app_me_response.g.dart';

@JsonSerializable()
class AppMeResponse {
  const AppMeResponse({
    required this.user,
    required this.device,
    required this.abilities,
  });

  factory AppMeResponse.fromJson(Map<String, Object?> json) =>
      _$AppMeResponseFromJson(json);

  final AppUserProfile user;
  final AppDevicePayload? device;
  final List<String> abilities;

  Map<String, Object?> toJson() => _$AppMeResponseToJson(this);
}
