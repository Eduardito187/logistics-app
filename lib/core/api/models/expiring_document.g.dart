// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expiring_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpiringDocument _$ExpiringDocumentFromJson(Map<String, dynamic> json) =>
    ExpiringDocument(
      ownerType: json['owner_type'] == null
          ? null
          : ExpiringDocumentOwnerType.fromJson(json['owner_type'] as String),
      ownerId: json['owner_id'] as String?,
      ownerLabel: json['owner_label'] as String?,
      documentType: json['document_type'] as String?,
      expiresOn: json['expires_on'] == null
          ? null
          : DateTime.parse(json['expires_on'] as String),
      expired: json['expired'] as bool?,
    );

Map<String, dynamic> _$ExpiringDocumentToJson(ExpiringDocument instance) =>
    <String, dynamic>{
      'owner_type': instance.ownerType,
      'owner_id': instance.ownerId,
      'owner_label': instance.ownerLabel,
      'document_type': instance.documentType,
      'expires_on': instance.expiresOn?.toIso8601String(),
      'expired': instance.expired,
    };
