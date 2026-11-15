// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_applied_promotion.dart';

part 'commerce_discount_quote.g.dart';

@JsonSerializable()
class CommerceDiscountQuote {
  const CommerceDiscountQuote({
    required this.applied,
    required this.totalDiscountCents,
    required this.freeShipping,
  });

  factory CommerceDiscountQuote.fromJson(Map<String, Object?> json) =>
      _$CommerceDiscountQuoteFromJson(json);

  final List<CommerceAppliedPromotion> applied;
  @JsonKey(name: 'total_discount_cents')
  final int totalDiscountCents;
  @JsonKey(name: 'free_shipping')
  final bool freeShipping;

  Map<String, Object?> toJson() => _$CommerceDiscountQuoteToJson(this);
}
