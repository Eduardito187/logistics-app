// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'integration_token_status.dart';

part 'integration_token.g.dart';

@JsonSerializable()
class IntegrationToken {
  const IntegrationToken({
    required this.id,
    required this.name,
    required this.tokenPrefix,
    required this.status,
    required this.permissionKeys,
    this.expiresAt,
    this.lastUsedAt,
    this.createdBy,
  });

  factory IntegrationToken.fromJson(Map<String, Object?> json) =>
      _$IntegrationTokenFromJson(json);

  final String id;
  final String name;

  /// Prefijo público del token; el secreto nunca se expone en lectura.
  @JsonKey(name: 'token_prefix')
  final String tokenPrefix;
  final IntegrationTokenStatus status;
  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'created_by')
  final String? createdBy;

  Map<String, Object?> toJson() => _$IntegrationTokenToJson(this);
}
