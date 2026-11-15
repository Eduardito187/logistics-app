// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'promotion_channel.dart';

part 'commerce_evaluate_promotions_request.g.dart';

@JsonSerializable()
class CommerceEvaluatePromotionsRequest {
  const CommerceEvaluatePromotionsRequest({
    required this.subtotalCents,
    required this.channel,
    this.couponCode,
  });

  factory CommerceEvaluatePromotionsRequest.fromJson(
    Map<String, Object?> json,
  ) => _$CommerceEvaluatePromotionsRequestFromJson(json);

  @JsonKey(name: 'subtotal_cents')
  final int subtotalCents;
  final PromotionChannel channel;
  @JsonKey(name: 'coupon_code')
  final String? couponCode;

  Map<String, Object?> toJson() =>
      _$CommerceEvaluatePromotionsRequestToJson(this);
}
