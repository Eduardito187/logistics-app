// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_promotion_conditions.dart';
import 'commerce_promotion_view_status.dart';
import 'commerce_promotion_view_type.dart';

part 'commerce_promotion_view.g.dart';

@JsonSerializable()
class CommercePromotionView {
  const CommercePromotionView({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.currency,
    required this.status,
    required this.version,
    required this.isCoupon,
    required this.freeShipping,
    this.code,
    this.conditions,
  });

  factory CommercePromotionView.fromJson(Map<String, Object?> json) =>
      _$CommercePromotionViewFromJson(json);

  final String id;
  final String name;
  final String? code;
  final CommercePromotionViewType type;

  /// Basis points (percentage), cents (fixed amount) or 0 (free shipping).
  final int value;
  final String currency;
  final CommercePromotionConditions? conditions;
  final CommercePromotionViewStatus status;
  final int version;
  @JsonKey(name: 'is_coupon')
  final bool isCoupon;
  @JsonKey(name: 'free_shipping')
  final bool freeShipping;

  Map<String, Object?> toJson() => _$CommercePromotionViewToJson(this);
}
