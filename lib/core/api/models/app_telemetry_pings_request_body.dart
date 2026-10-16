// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_ping.dart';

part 'app_telemetry_pings_request_body.g.dart';

@JsonSerializable()
class AppTelemetryPingsRequestBody {
  const AppTelemetryPingsRequestBody({
    required this.vehicleId,
    required this.pings,
    this.driverId,
    this.routeId,
  });

  factory AppTelemetryPingsRequestBody.fromJson(Map<String, Object?> json) =>
      _$AppTelemetryPingsRequestBodyFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'route_id')
  final String? routeId;
  final List<VehiclePing> pings;

  Map<String, Object?> toJson() => _$AppTelemetryPingsRequestBodyToJson(this);
}
