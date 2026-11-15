// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commerce_set_price_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommerceSetPriceRequest _$CommerceSetPriceRequestFromJson(
  Map<String, dynamic> json,
) => CommerceSetPriceRequest(
  sku: json['sku'] as String,
  grossAmountCents: (json['gross_amount_cents'] as num).toInt(),
  currency: json['currency'] as String?,
);

Map<String, dynamic> _$CommerceSetPriceRequestToJson(
  CommerceSetPriceRequest instance,
) => <String, dynamic>{
  'sku': instance.sku,
  'gross_amount_cents': instance.grossAmountCents,
  'currency': instance.currency,
};
