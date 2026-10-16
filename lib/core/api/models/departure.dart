// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'departure_status.dart';
import 'load.dart';

part 'departure.g.dart';

/// A vehicle departure/dispatch of the owned fleet
@JsonSerializable()
class Departure {
  const Departure({
    required this.id,
    required this.vehicleId,
    required this.helperIds,
    required this.load,
    required this.status,
    required this.departedAt,
    this.driverId,
    this.destination,
    this.routeRef,
    this.odometerOutKm,
    this.odometerInKm,
    this.kmTraveled,
    this.returnedAt,
    this.note,
  });

  factory Departure.fromJson(Map<String, Object?> json) =>
      _$DepartureFromJson(json);

  final String id;
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'helper_ids')
  final List<String> helperIds;
  final String? destination;
  @JsonKey(name: 'route_ref')
  final String? routeRef;
  final Load load;
  @JsonKey(name: 'odometer_out_km')
  final int? odometerOutKm;
  @JsonKey(name: 'odometer_in_km')
  final int? odometerInKm;
  @JsonKey(name: 'km_traveled')
  final int? kmTraveled;
  final DepartureStatus status;
  @JsonKey(name: 'departed_at')
  final DateTime departedAt;
  @JsonKey(name: 'returned_at')
  final DateTime? returnedAt;
  final String? note;

  Map<String, Object?> toJson() => _$DepartureToJson(this);
}
