// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'tariff.dart';

part 'get_app_carriers_tariffs_cheapest_response.g.dart';

@JsonSerializable()
class GetAppCarriersTariffsCheapestResponse {
  const GetAppCarriersTariffsCheapestResponse({required this.data});

  factory GetAppCarriersTariffsCheapestResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppCarriersTariffsCheapestResponseFromJson(json);

  final Tariff data;

  Map<String, Object?> toJson() =>
      _$GetAppCarriersTariffsCheapestResponseToJson(this);
}
