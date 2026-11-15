// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_evaluate_promotions_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceEvaluatePromotionsRequest _$CommerceEvaluatePromotionsRequestFromJson(
  Map<String, dynamic> json,
) => CommerceEvaluatePromotionsRequest(
  subtotalCents: (json['subtotal_cents'] as num).toInt(),
  channel: PromotionChannel.fromJson(json['channel'] as String),
  couponCode: json['coupon_code'] as String?,
);

Map<String, dynamic> _$CommerceEvaluatePromotionsRequestToJson(
  CommerceEvaluatePromotionsRequest instance,
) => <String, dynamic>{
  'subtotal_cents': instance.subtotalCents,
  'channel': instance.channel,
  'coupon_code': instance.couponCode,
};
