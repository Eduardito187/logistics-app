// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanRequest _$ScanRequestFromJson(Map<String, dynamic> json) => ScanRequest(
  shipmentId: json['shipment_id'] as String,
  unitId: json['unit_id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  deviceId: json['device_id'] as String?,
  userId: json['user_id'] as String?,
  idempotencyKey: json['idempotency_key'] as String?,
);

Map<String, dynamic> _$ScanRequestToJson(ScanRequest instance) =>
    <String, dynamic>{
      'shipment_id': instance.shipmentId,
      'unit_id': instance.unitId,
      'lat': instance.lat,
      'lng': instance.lng,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'device_id': instance.deviceId,
      'user_id': instance.userId,
      'idempotency_key': instance.idempotencyKey,
    };
