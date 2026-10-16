// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'vehicle_ping.dart';

part 'integrations_telemetry_pings_request_body.g.dart';

@JsonSerializable()
class IntegrationsTelemetryPingsRequestBody {
  const IntegrationsTelemetryPingsRequestBody({
    required this.vehicleId,
    required this.pings,
    this.driverId,
    this.routeId,
  });

  factory IntegrationsTelemetryPingsRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$IntegrationsTelemetryPingsRequestBodyFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'route_id')
  final String? routeId;
  final List<VehiclePing> pings;

  Map<String, Object?> toJson() =>
      _$IntegrationsTelemetryPingsRequestBodyToJson(this);
}
