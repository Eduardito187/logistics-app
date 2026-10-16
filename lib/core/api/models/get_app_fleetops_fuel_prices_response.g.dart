// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_app_fleetops_fuel_prices_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetAppFleetopsFuelPricesResponse _$GetAppFleetopsFuelPricesResponseFromJson(
  Map<String, dynamic> json,
) => GetAppFleetopsFuelPricesResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$GetAppFleetopsFuelPricesResponseToJson(
  GetAppFleetopsFuelPricesResponse instance,
) => <String, dynamic>{'data': instance.data};
