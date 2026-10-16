// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_expiry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentExpiry _$DocumentExpiryFromJson(Map<String, dynamic> json) =>
    DocumentExpiry(
      type: json['type'] as String,
      expiresOn: DateTime.parse(json['expires_on'] as String),
    );

Map<String, dynamic> _$DocumentExpiryToJson(DocumentExpiry instance) =>
    <String, dynamic>{
      'type': instance.type,
      'expires_on': instance.expiresOn.toIso8601String(),
    };
