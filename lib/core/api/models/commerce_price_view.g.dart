// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_price_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommercePriceView _$CommercePriceViewFromJson(Map<String, dynamic> json) =>
    CommercePriceView(
      priceListId: json['price_list_id'] as String,
      sku: json['sku'] as String,
      grossAmountCents: (json['gross_amount_cents'] as num).toInt(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$CommercePriceViewToJson(CommercePriceView instance) =>
    <String, dynamic>{
      'price_list_id': instance.priceListId,
      'sku': instance.sku,
      'gross_amount_cents': instance.grossAmountCents,
      'currency': instance.currency,
    };
