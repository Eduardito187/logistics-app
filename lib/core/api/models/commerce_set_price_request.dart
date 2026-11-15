// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_set_price_request.g.dart';

@JsonSerializable()
class CommerceSetPriceRequest {
  const CommerceSetPriceRequest({
    required this.sku,
    required this.grossAmountCents,
    this.currency,
  });

  factory CommerceSetPriceRequest.fromJson(Map<String, Object?> json) =>
      _$CommerceSetPriceRequestFromJson(json);

  final String sku;
  @JsonKey(name: 'gross_amount_cents')
  final int grossAmountCents;
  final String? currency;

  Map<String, Object?> toJson() => _$CommerceSetPriceRequestToJson(this);
}
