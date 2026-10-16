// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_access_tokens_request_body.g.dart';

@JsonSerializable()
class AppAccessTokensRequestBody {
  const AppAccessTokensRequestBody({
    required this.name,
    required this.permissionKeys,
    this.expiresAt,
  });

  factory AppAccessTokensRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAccessTokensRequestBodyFromJson(json);

  final String name;
  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => _$AppAccessTokensRequestBodyToJson(this);
}
