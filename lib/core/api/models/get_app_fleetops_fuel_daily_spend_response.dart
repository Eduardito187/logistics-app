// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'get_app_fleetops_fuel_daily_spend_response.g.dart';

@JsonSerializable()
class GetAppFleetopsFuelDailySpendResponse {
  const GetAppFleetopsFuelDailySpendResponse({required this.data});

  factory GetAppFleetopsFuelDailySpendResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppFleetopsFuelDailySpendResponseFromJson(json);

  final dynamic data;

  Map<String, Object?> toJson() =>
      _$GetAppFleetopsFuelDailySpendResponseToJson(this);
}
