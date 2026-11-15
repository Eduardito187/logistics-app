// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_create_promotion_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceCreatePromotionRequest _$CommerceCreatePromotionRequestFromJson(
  Map<String, dynamic> json,
) => CommerceCreatePromotionRequest(
  name: json['name'] as String,
  type: CommerceCreatePromotionRequestType.fromJson(json['type'] as String),
  value: (json['value'] as num).toInt(),
  currency: json['currency'] as String?,
  code: json['code'] as String?,
  minSubtotalCents: (json['min_subtotal_cents'] as num?)?.toInt(),
  channel: json['channel'] == null
      ? null
      : PromotionChannel.fromJson(json['channel'] as String),
  startsAt: json['starts_at'] as String?,
  endsAt: json['ends_at'] as String?,
);

Map<String, dynamic> _$CommerceCreatePromotionRequestToJson(
  CommerceCreatePromotionRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'value': instance.value,
  'currency': instance.currency,
  'code': instance.code,
  'min_subtotal_cents': instance.minSubtotalCents,
  'channel': instance.channel,
  'starts_at': instance.startsAt,
  'ends_at': instance.endsAt,
};
