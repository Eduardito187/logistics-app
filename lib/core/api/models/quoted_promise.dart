// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'quoted_promise_status.dart';

part 'quoted_promise.g.dart';

@JsonSerializable()
class QuotedPromise {
  const QuotedPromise({
    required this.shipmentRef,
    required this.zoneId,
    required this.slotDate,
    required this.timeSlot,
    required this.status,
  });

  factory QuotedPromise.fromJson(Map<String, Object?> json) =>
      _$QuotedPromiseFromJson(json);

  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @JsonKey(name: 'slot_date')
  final DateTime slotDate;
  @JsonKey(name: 'time_slot')
  final String timeSlot;
  final QuotedPromiseStatus status;

  Map<String, Object?> toJson() => _$QuotedPromiseToJson(this);
}
