// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_delivery_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProofOfDeliveryRequest _$ProofOfDeliveryRequestFromJson(
  Map<String, dynamic> json,
) => ProofOfDeliveryRequest(
  shipmentId: json['shipment_id'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  unitId: json['unit_id'] as String?,
  unitIds: (json['unit_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  lat: (json['lat'] as num?)?.toDouble(),
  lng: (json['lng'] as num?)?.toDouble(),
  location: json['location'] == null
      ? null
      : CapturedLocation.fromJson(json['location'] as Map<String, dynamic>),
  deviceId: json['device_id'] as String?,
  userId: json['user_id'] as String?,
  idempotencyKey: json['idempotency_key'] as String?,
  confirmation: json['confirmation'] as String?,
  photoUrl: json['photo_url'] as String?,
  photoPath: json['photo_path'] as String?,
  photoPaths: (json['photo_paths'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  evidenceIds: (json['evidence_ids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ProofOfDeliveryRequestToJson(
  ProofOfDeliveryRequest instance,
) => <String, dynamic>{
  'shipment_id': instance.shipmentId,
  'unit_id': instance.unitId,
  'unit_ids': instance.unitIds,
  'lat': instance.lat,
  'lng': instance.lng,
  'location': instance.location,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'device_id': instance.deviceId,
  'user_id': instance.userId,
  'idempotency_key': instance.idempotencyKey,
  'confirmation': instance.confirmation,
  'photo_url': instance.photoUrl,
  'photo_path': instance.photoPath,
  'photo_paths': instance.photoPaths,
  'evidence_ids': instance.evidenceIds,
};
