// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'commerce_price_view.g.dart';

@JsonSerializable()
class CommercePriceView {
  const CommercePriceView({
    required this.priceListId,
    required this.sku,
    required this.grossAmountCents,
    required this.currency,
  });

  factory CommercePriceView.fromJson(Map<String, Object?> json) =>
      _$CommercePriceViewFromJson(json);

  @JsonKey(name: 'price_list_id')
  final String priceListId;
  final String sku;
  @JsonKey(name: 'gross_amount_cents')
  final int grossAmountCents;
  final String currency;

  Map<String, Object?> toJson() => _$CommercePriceViewToJson(this);
}
