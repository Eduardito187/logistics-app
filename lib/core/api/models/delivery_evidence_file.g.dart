// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_evidence_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryEvidenceFile _$DeliveryEvidenceFileFromJson(
  Map<String, dynamic> json,
) => DeliveryEvidenceFile(
  kind: DeliveryEvidenceFileKind.fromJson(json['kind'] as String),
  url: json['url'] as String,
  capturedAt: json['captured_at'] == null
      ? null
      : DateTime.parse(json['captured_at'] as String),
  validationStatus: json['validation_status'] == null
      ? null
      : DeliveryEvidenceFileValidationStatus.fromJson(
          json['validation_status'] as String,
        ),
);

Map<String, dynamic> _$DeliveryEvidenceFileToJson(
  DeliveryEvidenceFile instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'url': instance.url,
  'captured_at': instance.capturedAt?.toIso8601String(),
  'validation_status': instance.validationStatus,
};
