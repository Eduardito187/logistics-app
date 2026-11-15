// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'app_auth2fa_confirm_request_body.g.dart';

@JsonSerializable()
class AppAuth2faConfirmRequestBody {
  const AppAuth2faConfirmRequestBody({required this.code});

  factory AppAuth2faConfirmRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppAuth2faConfirmRequestBodyFromJson(json);

  /// Código TOTP de 6 dígitos generado por la app autenticadora.
  final String code;

  Map<String, Object?> toJson() => _$AppAuth2faConfirmRequestBodyToJson(this);
}
