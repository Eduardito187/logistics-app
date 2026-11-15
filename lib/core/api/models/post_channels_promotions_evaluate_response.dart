// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_discount_quote.dart';

part 'post_channels_promotions_evaluate_response.g.dart';

@JsonSerializable()
class PostChannelsPromotionsEvaluateResponse {
  const PostChannelsPromotionsEvaluateResponse({required this.data});

  factory PostChannelsPromotionsEvaluateResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PostChannelsPromotionsEvaluateResponseFromJson(json);

  final CommerceDiscountQuote data;

  Map<String, Object?> toJson() =>
      _$PostChannelsPromotionsEvaluateResponseToJson(this);
}
