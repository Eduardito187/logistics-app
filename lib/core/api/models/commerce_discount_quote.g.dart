// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_discount_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceDiscountQuote _$CommerceDiscountQuoteFromJson(
  Map<String, dynamic> json,
) => CommerceDiscountQuote(
  applied: (json['applied'] as List<dynamic>)
      .map((e) => CommerceAppliedPromotion.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalDiscountCents: (json['total_discount_cents'] as num).toInt(),
  freeShipping: json['free_shipping'] as bool,
);

Map<String, dynamic> _$CommerceDiscountQuoteToJson(
  CommerceDiscountQuote instance,
) => <String, dynamic>{
  'applied': instance.applied,
  'total_discount_cents': instance.totalDiscountCents,
  'free_shipping': instance.freeShipping,
};
