// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reserved_delivery_slot.g.dart';

@JsonSerializable()
class ReservedDeliverySlot {
  const ReservedDeliverySlot({
    required this.orderId,
    required this.zoneId,
    required this.deliveryDate,
    required this.deliveryWindowStart,
    required this.deliveryWindowEnd,
  });

  factory ReservedDeliverySlot.fromJson(Map<String, Object?> json) =>
      _$ReservedDeliverySlotFromJson(json);

  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'zone_id')
  final String zoneId;
  @JsonKey(name: 'delivery_date')
  final DateTime deliveryDate;
  @JsonKey(name: 'delivery_window_start')
  final String deliveryWindowStart;
  @JsonKey(name: 'delivery_window_end')
  final String deliveryWindowEnd;

  Map<String, Object?> toJson() => _$ReservedDeliverySlotToJson(this);
}
