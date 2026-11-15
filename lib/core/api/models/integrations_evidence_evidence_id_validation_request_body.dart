// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'status4.dart';

part 'integrations_evidence_evidence_id_validation_request_body.g.dart';

@JsonSerializable()
class IntegrationsEvidenceEvidenceIdValidationRequestBody {
  const IntegrationsEvidenceEvidenceIdValidationRequestBody({
    this.status,
    this.ocrDocumentNumber,
    this.detail,
    this.validatedAt,
  });

  factory IntegrationsEvidenceEvidenceIdValidationRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$IntegrationsEvidenceEvidenceIdValidationRequestBodyFromJson(json);

  /// Estado decidido por el validador (gana sobre ocr_document_number si viene)
  final Status4? status;

  /// Número de documento leído por OCR; el backend lo cruza contra el del cliente
  @JsonKey(name: 'ocr_document_number')
  final String? ocrDocumentNumber;
  final String? detail;
  @JsonKey(name: 'validated_at')
  final DateTime? validatedAt;

  Map<String, Object?> toJson() =>
      _$IntegrationsEvidenceEvidenceIdValidationRequestBodyToJson(this);
}
