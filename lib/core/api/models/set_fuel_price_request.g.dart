// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_fuel_price_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetFuelPriceRequest _$SetFuelPriceRequestFromJson(Map<String, dynamic> json) =>
    SetFuelPriceRequest(
      fuelType: FuelType.fromJson(json['fuel_type'] as String),
      priceCents: (json['price_cents'] as num).toInt(),
      currency: json['currency'] as String,
      effectiveFrom: DateTime.parse(json['effective_from'] as String),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$SetFuelPriceRequestToJson(
  SetFuelPriceRequest instance,
) => <String, dynamic>{
  'fuel_type': instance.fuelType,
  'price_cents': instance.priceCents,
  'currency': instance.currency,
  'effective_from': instance.effectiveFrom.toIso8601String(),
  'source': instance.source,
};
