// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_evidence_validation_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecordEvidenceValidationData _$RecordEvidenceValidationDataFromJson(
  Map<String, dynamic> json,
) => RecordEvidenceValidationData(
  evidenceId: json['evidence_id'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$RecordEvidenceValidationDataToJson(
  RecordEvidenceValidationData instance,
) => <String, dynamic>{
  'evidence_id': instance.evidenceId,
  'status': instance.status,
};
