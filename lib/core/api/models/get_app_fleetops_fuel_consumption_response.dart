// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_app_fleetops_fuel_consumption_response.g.dart';

@JsonSerializable()
class GetAppFleetopsFuelConsumptionResponse {
  const GetAppFleetopsFuelConsumptionResponse({required this.data});

  factory GetAppFleetopsFuelConsumptionResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsFuelConsumptionResponseFromJson(json);

  final dynamic data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsFuelConsumptionResponseToJson(this);
}
