// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integrations_evidence_evidence_id_validation_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationsEvidenceEvidenceIdValidationRequestBody
_$IntegrationsEvidenceEvidenceIdValidationRequestBodyFromJson(
  Map<String, dynamic> json,
) => IntegrationsEvidenceEvidenceIdValidationRequestBody(
  status: json['status'] == null
      ? null
      : Status4.fromJson(json['status'] as String),
  ocrDocumentNumber: json['ocr_document_number'] as String?,
  detail: json['detail'] as String?,
  validatedAt: json['validated_at'] == null
      ? null
      : DateTime.parse(json['validated_at'] as String),
);

Map<String, dynamic>
_$IntegrationsEvidenceEvidenceIdValidationRequestBodyToJson(
  IntegrationsEvidenceEvidenceIdValidationRequestBody instance,
) => <String, dynamic>{
  'status': instance.status,
  'ocr_document_number': instance.ocrDocumentNumber,
  'detail': instance.detail,
  'validated_at': instance.validatedAt?.toIso8601String(),
};
