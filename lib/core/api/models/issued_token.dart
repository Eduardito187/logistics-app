// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'issued_token.g.dart';

/// Resultado de emitir o rotar un token. Revela el secreto en claro (plain_token) UNA sola vez.
@JsonSerializable()
class IssuedToken {
  const IssuedToken({
    required this.id,
    required this.name,
    required this.tokenPrefix,
    required this.plainToken,
    required this.permissionKeys,
    this.expiresAt,
  });

  factory IssuedToken.fromJson(Map<String, Object?> json) =>
      _$IssuedTokenFromJson(json);

  final String id;
  final String name;
  @JsonKey(name: 'token_prefix')
  final String tokenPrefix;

  /// Token completo "prefix.secret"; solo se revela aquí y no se puede recuperar después.
  @JsonKey(name: 'plain_token')
  final String plainToken;
  @JsonKey(name: 'permission_keys')
  final List<String> permissionKeys;
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => _$IssuedTokenToJson(this);
}
