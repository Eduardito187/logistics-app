// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'schedule_maintenance_request_type.dart';

part 'schedule_maintenance_request.g.dart';

@JsonSerializable()
class ScheduleMaintenanceRequest {
  const ScheduleMaintenanceRequest({
    required this.vehicleId,
    required this.type,
    required this.scheduledAt,
    this.odometerKm,
    this.workshop,
    this.note,
  });

  factory ScheduleMaintenanceRequest.fromJson(Map<String, Object?> json) =>
      _$ScheduleMaintenanceRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final ScheduleMaintenanceRequestType type;
  @JsonKey(name: 'odometer_km')
  final int? odometerKm;
  final String? workshop;
  @JsonKey(name: 'scheduled_at')
  final DateTime scheduledAt;
  final String? note;

  Map<String, Object?> toJson() => _$ScheduleMaintenanceRequestToJson(this);
}
