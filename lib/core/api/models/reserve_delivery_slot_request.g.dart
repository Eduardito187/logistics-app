// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reserve_delivery_slot_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReserveDeliverySlotRequest _$ReserveDeliverySlotRequestFromJson(
  Map<String, dynamic> json,
) => ReserveDeliverySlotRequest(
  orderId: json['order_id'] as String,
  zoneId: json['zone_id'] as String,
  date: DateTime.parse(json['date'] as String),
  windowStart: json['window_start'] as String,
  windowEnd: json['window_end'] as String,
);

Map<String, dynamic> _$ReserveDeliverySlotRequestToJson(
  ReserveDeliverySlotRequest instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'zone_id': instance.zoneId,
  'date': instance.date.toIso8601String(),
  'window_start': instance.windowStart,
  'window_end': instance.windowEnd,
};
