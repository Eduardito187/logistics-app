// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_evidence_file_kind.dart';
import 'delivery_evidence_file_validation_status.dart';

part 'delivery_evidence_file.g.dart';

@JsonSerializable()
class DeliveryEvidenceFile {
  const DeliveryEvidenceFile({
    required this.kind,
    required this.url,
    this.capturedAt,
    this.validationStatus,
  });

  factory DeliveryEvidenceFile.fromJson(Map<String, Object?> json) =>
      _$DeliveryEvidenceFileFromJson(json);

  /// signature = firma del cliente; pod = foto de la entrega; id_document = documento del cliente; damage = daño.
  final DeliveryEvidenceFileKind kind;

  /// Enlace para ver el archivo. No requiere cabeceras de autenticación; vence solo.
  final String url;
  @JsonKey(name: 'captured_at')
  final DateTime? capturedAt;
  @JsonKey(name: 'validation_status')
  final DeliveryEvidenceFileValidationStatus? validationStatus;

  Map<String, Object?> toJson() => _$DeliveryEvidenceFileToJson(this);
}
