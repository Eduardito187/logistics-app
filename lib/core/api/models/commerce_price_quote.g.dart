// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_price_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePriceQuote _$CommercePriceQuoteFromJson(Map<String, dynamic> json) =>
    CommercePriceQuote(
      sku: json['sku'] as String,
      channel: SalesChannel.fromJson(json['channel'] as String),
      netCents: (json['net_cents'] as num).toInt(),
      taxCents: (json['tax_cents'] as num).toInt(),
      grossCents: (json['gross_cents'] as num).toInt(),
      currency: json['currency'] as String,
      taxBreakdown: json['tax_breakdown'] == null
          ? null
          : TaxBreakdown.fromJson(
              json['tax_breakdown'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CommercePriceQuoteToJson(CommercePriceQuote instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'channel': instance.channel,
      'net_cents': instance.netCents,
      'tax_cents': instance.taxCents,
      'gross_cents': instance.grossCents,
      'currency': instance.currency,
      'tax_breakdown': instance.taxBreakdown,
    };
