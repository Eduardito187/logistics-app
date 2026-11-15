// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_promotion_conditions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePromotionConditions _$CommercePromotionConditionsFromJson(
  Map<String, dynamic> json,
) => CommercePromotionConditions(
  minSubtotalCents: (json['min_subtotal_cents'] as num).toInt(),
  channel: json['channel'] == null
      ? null
      : PromotionChannel.fromJson(json['channel'] as String),
  startsAt: json['starts_at'] as String?,
  endsAt: json['ends_at'] as String?,
);

Map<String, dynamic> _$CommercePromotionConditionsToJson(
  CommercePromotionConditions instance,
) => <String, dynamic>{
  'min_subtotal_cents': instance.minSubtotalCents,
  'channel': instance.channel,
  'starts_at': instance.startsAt,
  'ends_at': instance.endsAt,
};
