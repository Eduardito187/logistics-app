// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'customer.dart';
import 'delivery_evidence_kind.dart';
import 'delivery_evidence_validation_status.dart';
import 'location.dart';
import 'storage.dart';

part 'delivery_evidence.g.dart';

/// Evidencia de entrega ligada al cliente con su estado de validación anti-fraude. El `sha256` fija la integridad del archivo (una evidencia no se puede intercambiar por otra). `validation_status` es una señal, no un bloqueo.
@JsonSerializable()
class DeliveryEvidence {
  const DeliveryEvidence({
    required this.id,
    required this.shipmentId,
    required this.kind,
    required this.validationStatus,
    required this.sha256,
    required this.storage,
    required this.customer,
    required this.location,
    this.url,
    this.validationDetail,
    this.capturedAt,
    this.validatedAt,
  });

  factory DeliveryEvidence.fromJson(Map<String, Object?> json) =>
      _$DeliveryEvidenceFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_id')
  final String shipmentId;
  final DeliveryEvidenceKind kind;

  /// Enlace temporal firmado para VER el archivo (firma, foto o documento). Null si el archivo ya no existe. Vence solo: volver a pedir la lista para renovarlo.
  final String? url;
  @JsonKey(name: 'validation_status')
  final DeliveryEvidenceValidationStatus validationStatus;
  @JsonKey(name: 'validation_detail')
  final String? validationDetail;

  /// Hash SHA-256 del archivo (64 hex) — integridad de la evidencia
  final String sha256;
  final Storage storage;

  /// Snapshot de la identidad del cliente contra el que se valida la evidencia
  final Customer customer;
  final Location location;
  @JsonKey(name: 'captured_at')
  final DateTime? capturedAt;
  @JsonKey(name: 'validated_at')
  final DateTime? validatedAt;

  Map<String, Object?> toJson() => _$DeliveryEvidenceToJson(this);
}
