// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabelVerification _$LabelVerificationFromJson(Map<String, dynamic> json) =>
    LabelVerification(
      valid: json['valid'] as bool,
      result: LabelVerificationResult.fromJson(json['result'] as String),
    );

Map<String, dynamic> _$LabelVerificationToJson(LabelVerification instance) =>
    <String, dynamic>{'valid': instance.valid, 'result': instance.result};
