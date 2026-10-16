// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_price.dart';

part 'get_app_fleetops_fuel_prices_response.g.dart';

@JsonSerializable()
class GetAppFleetopsFuelPricesResponse {
  const GetAppFleetopsFuelPricesResponse({required this.data});

  factory GetAppFleetopsFuelPricesResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsFuelPricesResponseFromJson(json);

  final List<FuelPrice> data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsFuelPricesResponseToJson(this);
}
