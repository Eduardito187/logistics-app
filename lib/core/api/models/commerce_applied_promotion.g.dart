// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_applied_promotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceAppliedPromotion _$CommerceAppliedPromotionFromJson(
  Map<String, dynamic> json,
) => CommerceAppliedPromotion(
  promotionId: json['promotion_id'] as String,
  name: json['name'] as String,
  discountCents: (json['discount_cents'] as num).toInt(),
  freeShipping: json['free_shipping'] as bool,
);

Map<String, dynamic> _$CommerceAppliedPromotionToJson(
  CommerceAppliedPromotion instance,
) => <String, dynamic>{
  'promotion_id': instance.promotionId,
  'name': instance.name,
  'discount_cents': instance.discountCents,
  'free_shipping': instance.freeShipping,
};
