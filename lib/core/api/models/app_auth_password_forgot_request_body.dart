// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_auth_password_forgot_request_body.g.dart';

@JsonSerializable()
class AppAuthPasswordForgotRequestBody {
  const AppAuthPasswordForgotRequestBody({required this.email});

  factory AppAuthPasswordForgotRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppAuthPasswordForgotRequestBodyFromJson(json);

  /// Correo del usuario que solicita el reinicio.
  final String email;

  Map<String, Object?> toJson() =>
      _$AppAuthPasswordForgotRequestBodyToJson(this);
}
