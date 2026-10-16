// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_live.g.dart';

/// Posición en vivo de un vehículo (última lectura conocida).
@JsonSerializable()
class VehicleLive {
  const VehicleLive({
    required this.vehicleId,
    required this.lat,
    required this.lng,
    required this.moving,
    required this.recordedAt,
    this.speedKph,
    this.heading,
    this.ignition,
    this.routeId,
  });

  factory VehicleLive.fromJson(Map<String, Object?> json) =>
      _$VehicleLiveFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  final double lat;
  final double lng;
  @JsonKey(name: 'speed_kph')
  final double? speedKph;
  final int? heading;
  final bool? ignition;
  final bool moving;
  @JsonKey(name: 'route_id')
  final String? routeId;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;

  Map<String, Object?> toJson() => _$VehicleLiveToJson(this);
}
