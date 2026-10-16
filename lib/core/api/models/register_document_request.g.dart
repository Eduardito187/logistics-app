// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_document_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterDocumentRequest _$RegisterDocumentRequestFromJson(
  Map<String, dynamic> json,
) => RegisterDocumentRequest(
  ownerType: DocumentOwnerType.fromJson(json['owner_type'] as String),
  ownerId: json['owner_id'] as String,
  documentType: json['document_type'] as String,
  expiresOn: DateTime.parse(json['expires_on'] as String),
  issuedOn: json['issued_on'] == null
      ? null
      : DateTime.parse(json['issued_on'] as String),
  filePath: json['file_path'] as String?,
  note: json['note'] as String?,
  reference: json['reference'] as String?,
);

Map<String, dynamic> _$RegisterDocumentRequestToJson(
  RegisterDocumentRequest instance,
) => <String, dynamic>{
  'owner_type': instance.ownerType,
  'owner_id': instance.ownerId,
  'document_type': instance.documentType,
  'expires_on': instance.expiresOn.toIso8601String(),
  'issued_on': instance.issuedOn?.toIso8601String(),
  'file_path': instance.filePath,
  'note': instance.note,
  'reference': instance.reference,
};
