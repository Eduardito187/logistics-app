// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_price.dart';

part 'get_app_fleetops_fuel_prices_current_response.g.dart';

@JsonSerializable()
class GetAppFleetopsFuelPricesCurrentResponse {
  const GetAppFleetopsFuelPricesCurrentResponse({required this.data});

  factory GetAppFleetopsFuelPricesCurrentResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsFuelPricesCurrentResponseFromJson(json);

  final FuelPrice data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsFuelPricesCurrentResponseToJson(this);
}
