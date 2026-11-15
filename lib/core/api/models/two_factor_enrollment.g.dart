// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TwoFactorEnrollment _$TwoFactorEnrollmentFromJson(Map<String, dynamic> json) =>
    TwoFactorEnrollment(
      secret: json['secret'] as String,
      otpauthUri: json['otpauth_uri'] as String,
      recoveryCodes: (json['recovery_codes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TwoFactorEnrollmentToJson(
  TwoFactorEnrollment instance,
) => <String, dynamic>{
  'secret': instance.secret,
  'otpauth_uri': instance.otpauthUri,
  'recovery_codes': instance.recoveryCodes,
};
