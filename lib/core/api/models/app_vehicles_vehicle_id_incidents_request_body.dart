// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'severity.dart';
import 'type.dart';

part 'app_vehicles_vehicle_id_incidents_request_body.g.dart';

@JsonSerializable()
class AppVehiclesVehicleIdIncidentsRequestBody {
  const AppVehiclesVehicleIdIncidentsRequestBody({
    required this.severity,
    required this.type,
    this.routeId,
    this.note,
    this.lat,
    this.lng,
    this.occurredAt,
  });

  factory AppVehiclesVehicleIdIncidentsRequestBody.fromJson(
    Map<String, Object?> json,
  ) => _$AppVehiclesVehicleIdIncidentsRequestBodyFromJson(json);

  /// MINOR keeps the route with delayed ETAs; MAJOR reschedules pending stops to the next day.
  final Severity severity;
  final Type type;

  /// Optional; when omitted, the vehicle's current open route is used.
  @JsonKey(name: 'route_id')
  final String? routeId;
  final String? note;
  final double? lat;
  final double? lng;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;

  Map<String, Object?> toJson() =>
      _$AppVehiclesVehicleIdIncidentsRequestBodyToJson(this);
}
