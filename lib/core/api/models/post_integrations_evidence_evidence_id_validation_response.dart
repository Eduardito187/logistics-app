// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'record_evidence_validation_data.dart';

part 'post_integrations_evidence_evidence_id_validation_response.g.dart';

@JsonSerializable()
class PostIntegrationsEvidenceEvidenceIdValidationResponse {
  const PostIntegrationsEvidenceEvidenceIdValidationResponse({
    required this.data,
  });

  factory PostIntegrationsEvidenceEvidenceIdValidationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostIntegrationsEvidenceEvidenceIdValidationResponseFromJson(json);

  final RecordEvidenceValidationData data;

  Map<String, Object?> toJson() =>
      _$PostIntegrationsEvidenceEvidenceIdValidationResponseToJson(this);
}
