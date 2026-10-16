// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promise_offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PromiseOffer _$PromiseOfferFromJson(Map<String, dynamic> json) => PromiseOffer(
  slotDate: DateTime.parse(json['slot_date'] as String),
  weekday: (json['weekday'] as num).toInt(),
  timeSlot: json['time_slot'] as String,
  available: (json['available'] as num).toDouble(),
);

Map<String, dynamic> _$PromiseOfferToJson(PromiseOffer instance) =>
    <String, dynamic>{
      'slot_date': instance.slotDate.toIso8601String(),
      'weekday': instance.weekday,
      'time_slot': instance.timeSlot,
      'available': instance.available,
    };
