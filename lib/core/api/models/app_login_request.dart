// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device.dart';

part 'app_login_request.g.dart';

@JsonSerializable()
class AppLoginRequest {
  const AppLoginRequest({
    required this.email,
    required this.password,
    required this.device,
  });

  factory AppLoginRequest.fromJson(Map<String, Object?> json) =>
      _$AppLoginRequestFromJson(json);

  final String email;
  final String password;
  final Device device;

  Map<String, Object?> toJson() => _$AppLoginRequestToJson(this);
}
