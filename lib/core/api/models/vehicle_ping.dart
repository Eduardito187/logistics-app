// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'vehicle_ping.g.dart';

/// Una lectura GPS de un vehículo. Posición e instante obligatorios; el resto de la telemetría es opcional.
@JsonSerializable()
class VehiclePing {
  const VehiclePing({
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speedKph,
    this.heading,
    this.accuracyM,
    this.ignition,
    this.odometerM,
    this.deviceId,
  });

  factory VehiclePing.fromJson(Map<String, Object?> json) =>
      _$VehiclePingFromJson(json);

  final double lat;
  final double lng;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;
  @JsonKey(name: 'speed_kph')
  final double? speedKph;
  final int? heading;
  @JsonKey(name: 'accuracy_m')
  final double? accuracyM;
  final bool? ignition;
  @JsonKey(name: 'odometer_m')
  final int? odometerM;
  @JsonKey(name: 'device_id')
  final String? deviceId;

  Map<String, Object?> toJson() => _$VehiclePingToJson(this);
}
