// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'street_traffic.dart';

part 'get_app_telemetry_streets_response.g.dart';

@JsonSerializable()
class GetAppTelemetryStreetsResponse {
  const GetAppTelemetryStreetsResponse({required this.data});

  factory GetAppTelemetryStreetsResponse.fromJson(Map<String, Object?> json) =>
      _$GetAppTelemetryStreetsResponseFromJson(json);

  final List<StreetTraffic> data;

  Map<String, Object?> toJson() => _$GetAppTelemetryStreetsResponseToJson(this);
}
