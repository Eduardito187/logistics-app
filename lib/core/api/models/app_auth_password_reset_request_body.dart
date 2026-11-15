// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_auth_password_reset_request_body.g.dart';

@JsonSerializable()
class AppAuthPasswordResetRequestBody {
  const AppAuthPasswordResetRequestBody({
    required this.email,
    required this.code,
    required this.password,
  });

  factory AppAuthPasswordResetRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAuthPasswordResetRequestBodyFromJson(json);

  /// Correo del usuario.
  final String email;

  /// Código OTP recibido por correo.
  final String code;

  /// Nueva contraseña.
  final String password;

  Map<String, Object?> toJson() =>
      _$AppAuthPasswordResetRequestBodyToJson(this);
}
