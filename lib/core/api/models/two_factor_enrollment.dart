// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'two_factor_enrollment.g.dart';

@JsonSerializable()
class TwoFactorEnrollment {
  const TwoFactorEnrollment({
    required this.secret,
    required this.otpauthUri,
    required this.recoveryCodes,
  });

  factory TwoFactorEnrollment.fromJson(Map<String, Object?> json) =>
      _$TwoFactorEnrollmentFromJson(json);

  /// Secreto TOTP en base32 para la app autenticadora.
  final String secret;

  /// URI otpauth:// para generar el QR de enrolamiento.
  @JsonKey(name: 'otpauth_uri')
  final String otpauthUri;

  /// Códigos de recuperación de un solo uso.
  @JsonKey(name: 'recovery_codes')
  final List<String> recoveryCodes;

  Map<String, Object?> toJson() => _$TwoFactorEnrollmentToJson(this);
}
