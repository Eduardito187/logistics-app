// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'odometer_reading.dart';

part 'get_app_fleetops_odometer_response.g.dart';

@JsonSerializable()
class GetAppFleetopsOdometerResponse {
  const GetAppFleetopsOdometerResponse({required this.data});

  factory GetAppFleetopsOdometerResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppFleetopsOdometerResponseFromJson(json);

  final List<OdometerReading> data;

  Map<String, Object?> toJson() => _$GetAppFleetopsOdometerResponseToJson(this);
}
