// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'commerce_create_promotion_request_type.dart';
import 'promotion_channel.dart';

part 'commerce_create_promotion_request.g.dart';

@JsonSerializable()
class CommerceCreatePromotionRequest {
  const CommerceCreatePromotionRequest({
    required this.name,
    required this.type,
    required this.value,
    this.currency,
    this.code,
    this.minSubtotalCents,
    this.channel,
    this.startsAt,
    this.endsAt,
  });

  factory CommerceCreatePromotionRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceCreatePromotionRequestFromJson(json);

  final String name;
  final CommerceCreatePromotionRequestType type;
  final int value;
  final String? currency;
  final String? code;
  @JsonKey(name: 'min_subtotal_cents')
  final int? minSubtotalCents;
  final PromotionChannel? channel;
  @JsonKey(name: 'starts_at')
  final String? startsAt;
  @JsonKey(name: 'ends_at')
  final String? endsAt;

  Map<String, Object?> toJson() => _$CommerceCreatePromotionRequestToJson(this);
}
