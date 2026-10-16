// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'promise_status.dart';

part 'promise.g.dart';

@JsonSerializable()
class Promise {
  const Promise({
    required this.id,
    required this.shipmentRef,
    required this.zoneId,
    required this.zoneName,
    required this.slotDate,
    required this.timeSlot,
    required this.status,
    required this.reservedUntil,
  });

  factory Promise.fromJson(Map<String, Object?> json) =>
      _$PromiseFromJson(json);

  final String id;
  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;
  @JsonKey(name: 'zone_id')
  final String zoneId;

  /// Human-readable coverage zone name resolved from zone_id; null when the zone no longer exists.
  @JsonKey(name: 'zone_name')
  final String? zoneName;
  @JsonKey(name: 'slot_date')
  final DateTime slotDate;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final PromiseStatus status;

  /// RFC 3339 instant until which the reservation holds; null when not reserved.
  @JsonKey(name: 'reserved_until')
  final DateTime? reservedUntil;

  Map<String, Object?> toJson() => _$PromiseToJson(this);
}
