// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanEvent _$ScanEventFromJson(Map<String, dynamic> json) => ScanEvent(
  id: json['id'] as String,
  deliveryId: json['delivery_id'] as String,
  type: ScanType.fromJson(json['type'] as String),
  unitId: json['unit_id'] as String,
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  deviceId: json['device_id'] as String,
  userId: json['user_id'] as String,
  occurredAt: DateTime.parse(json['occurred_at'] as String),
  idempotencyKey: json['idempotency_key'] as String,
);

Map<String, dynamic> _$ScanEventToJson(ScanEvent instance) => <String, dynamic>{
  'id': instance.id,
  'delivery_id': instance.deliveryId,
  'type': instance.type,
  'unit_id': instance.unitId,
  'lat': instance.lat,
  'lng': instance.lng,
  'device_id': instance.deviceId,
  'user_id': instance.userId,
  'occurred_at': instance.occurredAt.toIso8601String(),
  'idempotency_key': instance.idempotencyKey,
};
