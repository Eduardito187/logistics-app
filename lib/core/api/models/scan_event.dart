// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'scan_type.dart';

part 'scan_event.g.dart';

@JsonSerializable()
class ScanEvent {
  const ScanEvent({
    required this.id,
    required this.deliveryId,
    required this.type,
    required this.unitId,
    required this.lat,
    required this.lng,
    required this.deviceId,
    required this.userId,
    required this.occurredAt,
    required this.idempotencyKey,
  });

  factory ScanEvent.fromJson(Map<String, Object?> json) =>
      _$ScanEventFromJson(json);

  final String id;
  @JsonKey(name: 'delivery_id')
  final String deliveryId;
  final ScanType type;
  @JsonKey(name: 'unit_id')
  final String unitId;
  final double lat;
  final double lng;
  @JsonKey(name: 'device_id')
  final String deviceId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @JsonKey(name: 'idempotency_key')
  final String idempotencyKey;

  Map<String, Object?> toJson() => _$ScanEventToJson(this);
}
