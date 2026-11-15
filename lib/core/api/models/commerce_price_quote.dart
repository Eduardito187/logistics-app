// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sales_channel.dart';
import 'tax_breakdown.dart';

part 'commerce_price_quote.g.dart';

@JsonSerializable()
class CommercePriceQuote {
  const CommercePriceQuote({
    required this.sku,
    required this.channel,
    required this.netCents,
    required this.taxCents,
    required this.grossCents,
    required this.currency,
    this.taxBreakdown,
  });

  factory CommercePriceQuote.fromJson(Map<String, Object?> json) =>
      _$CommercePriceQuoteFromJson(json);

  final String sku;
  final SalesChannel channel;
  @JsonKey(name: 'net_cents')
  final int netCents;

  /// Total taxes included in the gross amount.
  @JsonKey(name: 'tax_cents')
  final int taxCents;
  @JsonKey(name: 'gross_cents')
  final int grossCents;
  final String currency;
  @JsonKey(name: 'tax_breakdown')
  final TaxBreakdown? taxBreakdown;

  Map<String, Object?> toJson() => _$CommercePriceQuoteToJson(this);
}
