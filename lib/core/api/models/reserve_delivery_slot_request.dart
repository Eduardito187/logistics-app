// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reserve_delivery_slot_request.g.dart';

@JsonSerializable()
class ReserveDeliverySlotRequest {
  const ReserveDeliverySlotRequest({
    required this.orderId,
    required this.zoneId,
    required this.date,
    required this.windowStart,
    required this.windowEnd,
  });

  factory ReserveDeliverySlotRequest.fromJson(Map<String, Object?> json) =>
      _$ReserveDeliverySlotRequestFromJson(json);

  /// Shipment (order) identifier.
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'zone_id')
  final String zoneId;
  final DateTime date;

  /// Window start in HH:MM (24h).
  @JsonKey(name: 'window_start')
  final String windowStart;

  /// Window end in HH:MM (24h).
  @JsonKey(name: 'window_end')
  final String windowEnd;

  Map<String, Object?> toJson() => _$ReserveDeliverySlotRequestToJson(this);
}
