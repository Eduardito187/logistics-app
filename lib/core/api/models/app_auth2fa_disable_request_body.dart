// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_auth2fa_disable_request_body.g.dart';

@JsonSerializable()
class AppAuth2faDisableRequestBody {
  const AppAuth2faDisableRequestBody({this.code, this.password});

  factory AppAuth2faDisableRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAuth2faDisableRequestBodyFromJson(json);

  /// Código TOTP de 6 dígitos.
  final String? code;

  /// Contraseña actual de la cuenta.
  final String? password;

  Map<String, Object?> toJson() => _$AppAuth2faDisableRequestBodyToJson(this);
}
