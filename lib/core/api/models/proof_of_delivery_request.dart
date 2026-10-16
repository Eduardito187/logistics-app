// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'proof_of_delivery_request.g.dart';

@JsonSerializable()
class ProofOfDeliveryRequest {
  const ProofOfDeliveryRequest({
    required this.shipmentId,
    required this.unitId,
    required this.lat,
    required this.lng,
    required this.occurredAt,
    required this.confirmation,
    this.deviceId,
    this.userId,
    this.idempotencyKey,
    this.photoUrl,
    this.photoPath,
  });

  factory ProofOfDeliveryRequest.fromJson(Map<String, Object?> json) =>
      _$ProofOfDeliveryRequestFromJson(json);

  @JsonKey(name: 'shipment_id')
  final String shipmentId;

  /// Bulto escaneado
  @JsonKey(name: 'unit_id')
  final String unitId;
  final double lat;
  final double lng;

  /// Momento del escaneo, fijado por la app en terreno (offline-first)
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  /// Puede inyectarlo el token de Auth; opcional en el cuerpo
  @JsonKey(name: 'device_id')
  final String? deviceId;

  /// Puede inyectarlo el token de Auth; opcional en el cuerpo
  @JsonKey(name: 'user_id')
  final String? userId;

  /// Clave de idempotencia; alternativa al header Idempotency-Key. Obligatoria por una de las dos vías; no puede ir vacía.
  @JsonKey(name: 'idempotency_key')
  final String? idempotencyKey;

  /// QR del cliente o firma
  final String confirmation;

  /// URL de acceso devuelta por el endpoint de subida de fotos (conveniencia)
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  /// Referencia durable (path en el disco de evidencia) devuelta por la subida de fotos; es la que se guarda en la prueba de entrega
  @JsonKey(name: 'photo_path')
  final String? photoPath;

  Map<String, Object?> toJson() => _$ProofOfDeliveryRequestToJson(this);
}
