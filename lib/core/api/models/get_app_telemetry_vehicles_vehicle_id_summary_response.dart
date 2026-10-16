// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_telemetry_summary.dart';

part 'get_app_telemetry_vehicles_vehicle_id_summary_response.g.dart';

@JsonSerializable()
class GetAppTelemetryVehiclesVehicleIdSummaryResponse {
  const GetAppTelemetryVehiclesVehicleIdSummaryResponse({required this.data});

  factory GetAppTelemetryVehiclesVehicleIdSummaryResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryVehiclesVehicleIdSummaryResponseFromJson(json);

  final VehicleTelemetrySummary data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryVehiclesVehicleIdSummaryResponseToJson(this);
}
