// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'captured_location.dart';

part 'proof_of_delivery_request.g.dart';

/// One proof of delivery for one or many products of the shipment (unit_id or unit_ids), with a single confirmation/signature/GPS. Idempotent. A photo is mandatory (photo_path or photo_paths).
@JsonSerializable()
class ProofOfDeliveryRequest {
  const ProofOfDeliveryRequest({
    required this.shipmentId,
    required this.occurredAt,
    this.unitId,
    this.unitIds,
    this.lat,
    this.lng,
    this.location,
    this.deviceId,
    this.userId,
    this.idempotencyKey,
    this.confirmation,
    this.photoUrl,
    this.photoPath,
    this.photoPaths,
    this.evidenceIds,
  });

  factory ProofOfDeliveryRequest.fromJson(Map<String, Object?> json) =>
      _$ProofOfDeliveryRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Single product; optional when unit_ids is sent.
  @JsonKey(name: 'unit_id')
  final String? unitId;
  @JsonKey(name: 'unit_ids')
  final List<String>? unitIds;
  final double? lat;
  final double? lng;
  final CapturedLocation? location;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  /// Signature/confirmation. Optional for carrier users (CARRIER_HANDOVER) and the store counter (STORE_PICKUP_HANDOVER); the customer QR is never required.
  final String? confirmation;

  /// URL de acceso devuelta por el endpoint de subida de fotos (conveniencia)
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  /// Durable `path` returned by POST /app/deliveries/photos. OPTIONAL (option A, async POD): the delivery is not blocked if the photo has not uploaded yet; it links automatically when it does. If a reference IS sent it must exist on the evidence disk, else 422 errors.photo_path.
  @JsonKey(name: 'photo_path')
  final String? photoPath;

  /// Each entry must exist on the evidence disk (same 422 as photo_path).
  @JsonKey(name: 'photo_paths')
  final List<String>? photoPaths;

  /// Optional anti-fraud evidence already captured for this shipment (POST /app/deliveries/evidence).
  @JsonKey(name: 'evidence_ids')
  final List<String>? evidenceIds;

  Map<String, Object?> toJson() => _$ProofOfDeliveryRequestToJson(this);
}
