// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_change_promotion_rules_request_type.dart';
import 'promotion_channel.dart';

part 'commerce_change_promotion_rules_request.g.dart';

@JsonSerializable()
class CommerceChangePromotionRulesRequest {
  const CommerceChangePromotionRulesRequest({
    required this.type,
    required this.value,
    this.minSubtotalCents,
    this.channel,
    this.startsAt,
    this.endsAt,
  });

  factory CommerceChangePromotionRulesRequest.fromJson(
    Map<String, Object?> json,
  ) => _$CommerceChangePromotionRulesRequestFromJson(json);

  final CommerceChangePromotionRulesRequestType type;
  final int value;
  @JsonKey(name: 'min_subtotal_cents')
  final int? minSubtotalCents;
  final PromotionChannel? channel;
  @JsonKey(name: 'starts_at')
  final String? startsAt;
  @JsonKey(name: 'ends_at')
  final String? endsAt;

  Map<String, Object?> toJson() =>
      _$CommerceChangePromotionRulesRequestToJson(this);
}
