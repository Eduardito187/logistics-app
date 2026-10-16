// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_telemetry_summary.g.dart';

/// Resumen diario de telemetría de un vehículo.
@JsonSerializable()
class VehicleTelemetrySummary {
  const VehicleTelemetrySummary({
    required this.vehicleId,
    required this.date,
    required this.distanceM,
    required this.movingS,
    required this.idleS,
    required this.trips,
    required this.maxSpeedKph,
    this.firstRecordedAt,
    this.lastRecordedAt,
  });

  factory VehicleTelemetrySummary.fromJson(Map<String, Object?> json) =>
      _$VehicleTelemetrySummaryFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final DateTime date;
  @JsonKey(name: 'distance_m')
  final double distanceM;
  @JsonKey(name: 'moving_s')
  final int movingS;
  @JsonKey(name: 'idle_s')
  final int idleS;
  final int trips;
  @JsonKey(name: 'max_speed_kph')
  final double maxSpeedKph;
  @JsonKey(name: 'first_recorded_at')
  final DateTime? firstRecordedAt;
  @JsonKey(name: 'last_recorded_at')
  final DateTime? lastRecordedAt;

  Map<String, Object?> toJson() => _$VehicleTelemetrySummaryToJson(this);
}
