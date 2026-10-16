// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_type.dart';

part 'fuel_price.g.dart';

/// A fuel price per liter effective from a date
@JsonSerializable()
class FuelPrice {
  const FuelPrice({
    required this.id,
    required this.fuelType,
    required this.priceCents,
    required this.currency,
    required this.effectiveFrom,
    this.source,
  });

  factory FuelPrice.fromJson(Map<String, Object?> json) =>
      _$FuelPriceFromJson(json);

  final String id;
  @JsonKey(name: 'fuel_type')
  final FuelType fuelType;
  @JsonKey(name: 'price_cents')
  final int priceCents;
  final String currency;
  @JsonKey(name: 'effective_from')
  final DateTime effectiveFrom;
  final String? source;

  Map<String, Object?> toJson() => _$FuelPriceToJson(this);
}
