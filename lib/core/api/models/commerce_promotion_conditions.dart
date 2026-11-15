// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'promotion_channel.dart';

part 'commerce_promotion_conditions.g.dart';

@JsonSerializable()
class CommercePromotionConditions {
  const CommercePromotionConditions({
    required this.minSubtotalCents,
    required this.channel,
    required this.startsAt,
    required this.endsAt,
  });

  factory CommercePromotionConditions.fromJson(Map<String, Object?> json) =>
      _$CommercePromotionConditionsFromJson(json);

  @JsonKey(name: 'min_subtotal_cents')
  final int minSubtotalCents;
  final PromotionChannel? channel;
  @JsonKey(name: 'starts_at')
  final String? startsAt;
  @JsonKey(name: 'ends_at')
  final String? endsAt;

  Map<String, Object?> toJson() => _$CommercePromotionConditionsToJson(this);
}
