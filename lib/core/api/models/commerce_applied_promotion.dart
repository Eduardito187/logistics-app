// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_applied_promotion.g.dart';

@JsonSerializable()
class CommerceAppliedPromotion {
  const CommerceAppliedPromotion({
    required this.promotionId,
    required this.name,
    required this.discountCents,
    required this.freeShipping,
  });

  factory CommerceAppliedPromotion.fromJson(Map<String, Object?> json) =>
      _$CommerceAppliedPromotionFromJson(json);

  @JsonKey(name: 'promotion_id')
  final String promotionId;
  final String name;
  @JsonKey(name: 'discount_cents')
  final int discountCents;
  @JsonKey(name: 'free_shipping')
  final bool freeShipping;

  Map<String, Object?> toJson() => _$CommerceAppliedPromotionToJson(this);
}
