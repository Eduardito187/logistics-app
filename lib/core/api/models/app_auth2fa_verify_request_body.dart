// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_auth2fa_verify_request_body.g.dart';

@JsonSerializable()
class AppAuth2faVerifyRequestBody {
  const AppAuth2faVerifyRequestBody({
    required this.challengeId,
    required this.code,
    this.email,
  });

  factory AppAuth2faVerifyRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAuth2faVerifyRequestBodyFromJson(json);

  /// Identificador del desafío devuelto por /app/auth/login.
  @JsonKey(name: 'challenge_id')
  final String challengeId;

  /// Código TOTP o de recuperación.
  final String code;

  /// Correo del usuario (opcional, refuerza la validación del desafío).
  final String? email;

  Map<String, Object?> toJson() => _$AppAuth2faVerifyRequestBodyToJson(this);
}
