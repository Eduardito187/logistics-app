// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'trip.dart';

part 'get_app_telemetry_trips_response.g.dart';

@JsonSerializable()
class GetAppTelemetryTripsResponse {
  const GetAppTelemetryTripsResponse({required this.data});

  factory GetAppTelemetryTripsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppTelemetryTripsResponseFromJson(json);

  final List<Trip> data;

  Map<String, Object?> toJson() => _$GetAppTelemetryTripsResponseToJson(this);
}
