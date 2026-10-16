// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_token_response.g.dart';

@JsonSerializable()
class AppTokenResponse {
  const AppTokenResponse({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
  });

  factory AppTokenResponse.fromJson(Map<String, Object?> json) =>
      _$AppTokenResponseFromJson(json);

  final String token;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => _$AppTokenResponseToJson(this);
}
