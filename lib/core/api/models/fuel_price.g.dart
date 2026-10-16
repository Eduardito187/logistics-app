// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelPrice _$FuelPriceFromJson(Map<String, dynamic> json) => FuelPrice(
  id: json['id'] as String,
  fuelType: FuelType.fromJson(json['fuel_type'] as String),
  priceCents: (json['price_cents'] as num).toInt(),
  currency: json['currency'] as String,
  effectiveFrom: DateTime.parse(json['effective_from'] as String),
  source: json['source'] as String?,
);

Map<String, dynamic> _$FuelPriceToJson(FuelPrice instance) => <String, dynamic>{
  'id': instance.id,
  'fuel_type': instance.fuelType,
  'price_cents': instance.priceCents,
  'currency': instance.currency,
  'effective_from': instance.effectiveFrom.toIso8601String(),
  'source': instance.source,
};
