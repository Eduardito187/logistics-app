// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'quote_promise_request.g.dart';

@JsonSerializable()
class QuotePromiseRequest {
  const QuotePromiseRequest({
    required this.shipmentRef,
    required this.zoneId,
    required this.slotDate,
    required this.timeSlot,
  });

  factory QuotePromiseRequest.fromJson(Map<String, Object?> json) =>
      _$QuotePromiseRequestFromJson(json);

  @JsonKey(name: 'shipment_ref')
  final String shipmentRef;
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @JsonKey(name: 'slot_date')
  final DateTime slotDate;
  @JsonKey(name: 'time_slot')
  final String timeSlot;

  Map<String, Object?> toJson() => _$QuotePromiseRequestToJson(this);
}
