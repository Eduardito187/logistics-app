// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StaffDocument _$StaffDocumentFromJson(Map<String, dynamic> json) =>
    StaffDocument(
      id: json['id'] as String?,
      source: json['source'] == null
          ? null
          : StaffDocumentSource.fromJson(json['source'] as String),
      documentType: json['document_type'] as String?,
      reference: json['reference'] as String?,
      issuedOn: json['issued_on'] == null
          ? null
          : DateTime.parse(json['issued_on'] as String),
      expiresOn: json['expires_on'] == null
          ? null
          : DateTime.parse(json['expires_on'] as String),
      expired: json['expired'] as bool?,
      note: json['note'] as String?,
      mimeType: json['mime_type'] as String?,
      url: json['url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$StaffDocumentToJson(StaffDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'document_type': instance.documentType,
      'reference': instance.reference,
      'issued_on': instance.issuedOn?.toIso8601String(),
      'expires_on': instance.expiresOn?.toIso8601String(),
      'expired': instance.expired,
      'note': instance.note,
      'mime_type': instance.mimeType,
      'url': instance.url,
      'created_at': instance.createdAt?.toIso8601String(),
    };
