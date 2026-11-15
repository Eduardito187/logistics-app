// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_utilization.g.dart';

@JsonSerializable()
class VehicleUtilization {
  const VehicleUtilization({
    required this.vehicleId,
    required this.vehiclePlate,
    required this.from,
    required this.to,
    required this.departuresCount,
    required this.kmTraveled,
    required this.hoursOnRoad,
    required this.lastOdometerKm,
    required this.lastOdometerReadAt,
  });

  factory VehicleUtilization.fromJson(Map<String, Object?> json) =>
      _$VehicleUtilizationFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;
  final DateTime from;
  final DateTime to;
  @JsonKey(name: 'departures_count')
  final int departuresCount;
  @JsonKey(name: 'km_traveled')
  final int kmTraveled;
  @JsonKey(name: 'hours_on_road')
  final num hoursOnRoad;
  @JsonKey(name: 'last_odometer_km')
  final int? lastOdometerKm;
  @JsonKey(name: 'last_odometer_read_at')
  final DateTime? lastOdometerReadAt;

  Map<String, Object?> toJson() => _$VehicleUtilizationToJson(this);
}
