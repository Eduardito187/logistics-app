// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserved_delivery_slot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReservedDeliverySlot _$ReservedDeliverySlotFromJson(
  Map<String, dynamic> json,
) => ReservedDeliverySlot(
  orderId: json['order_id'] as String,
  zoneId: json['zone_id'] as String,
  deliveryDate: DateTime.parse(json['delivery_date'] as String),
  deliveryWindowStart: json['delivery_window_start'] as String,
  deliveryWindowEnd: json['delivery_window_end'] as String,
);

Map<String, dynamic> _$ReservedDeliverySlotToJson(
  ReservedDeliverySlot instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'zone_id': instance.zoneId,
  'delivery_date': instance.deliveryDate.toIso8601String(),
  'delivery_window_start': instance.deliveryWindowStart,
  'delivery_window_end': instance.deliveryWindowEnd,
};
