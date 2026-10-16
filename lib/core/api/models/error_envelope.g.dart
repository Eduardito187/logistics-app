// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorEnvelope _$ErrorEnvelopeFromJson(Map<String, dynamic> json) =>
    ErrorEnvelope(
      error: Error4.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ErrorEnvelopeToJson(ErrorEnvelope instance) =>
    <String, dynamic>{'error': instance.error};
