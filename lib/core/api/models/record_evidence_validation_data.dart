// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'record_evidence_validation_data.g.dart';

@JsonSerializable()
class RecordEvidenceValidationData {
  const RecordEvidenceValidationData({this.evidenceId, this.status});

  factory RecordEvidenceValidationData.fromJson(Map<String, Object?> json) =>
      _$RecordEvidenceValidationDataFromJson(json);

  @JsonKey(name: 'evidence_id')
  final String? evidenceId;
  final String? status;

  Map<String, Object?> toJson() => _$RecordEvidenceValidationDataToJson(this);
}
