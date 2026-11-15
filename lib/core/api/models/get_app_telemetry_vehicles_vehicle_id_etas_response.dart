// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_eta.dart';

part 'get_app_telemetry_vehicles_vehicle_id_etas_response.g.dart';

@JsonSerializable()
class GetAppTelemetryVehiclesVehicleIdEtasResponse {
  const GetAppTelemetryVehiclesVehicleIdEtasResponse({required this.data});

  factory GetAppTelemetryVehiclesVehicleIdEtasResponse.fromJson(
    Map<String, Object?> json,
  ) => _$GetAppTelemetryVehiclesVehicleIdEtasResponseFromJson(json);

  final VehicleEta data;

  Map<String, Object?> toJson() =>
      _$GetAppTelemetryVehiclesVehicleIdEtasResponseToJson(this);
}
