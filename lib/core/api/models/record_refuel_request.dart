// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'fuel_type.dart';

part 'record_refuel_request.g.dart';

@JsonSerializable()
class RecordRefuelRequest {
  const RecordRefuelRequest({
    required this.vehicleId,
    required this.fuelType,
    required this.liters,
    required this.pricePerLiterCents,
    required this.currency,
    required this.fullTank,
    required this.refueledAt,
    this.driverId,
    this.odometerKm,
    this.station,
    this.note,
  });

  factory RecordRefuelRequest.fromJson(Map<String, Object?> json) =>
      _$RecordRefuelRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'fuel_type')
  final FuelType fuelType;
  final double liters;
  @JsonKey(name: 'price_per_liter_cents')
  final int pricePerLiterCents;
  final String currency;
  @JsonKey(name: 'odometer_km')
  final int? odometerKm;
  final String? station;
  @JsonKey(name: 'full_tank')
  final bool fullTank;
  @JsonKey(name: 'refueled_at')
  final DateTime refueledAt;
  final String? note;

  Map<String, Object?> toJson() => _$RecordRefuelRequestToJson(this);
}
