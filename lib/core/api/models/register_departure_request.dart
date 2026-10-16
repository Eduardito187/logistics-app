// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'load2.dart';

part 'register_departure_request.g.dart';

@JsonSerializable()
class RegisterDepartureRequest {
  const RegisterDepartureRequest({
    required this.vehicleId,
    required this.departedAt,
    this.driverId,
    this.helperIds,
    this.destination,
    this.routeRef,
    this.load,
    this.odometerOutKm,
    this.note,
  });

  factory RegisterDepartureRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterDepartureRequestFromJson(json);

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'helper_ids')
  final List<String>? helperIds;
  final String? destination;
  @JsonKey(name: 'route_ref')
  final String? routeRef;
  final Load2? load;
  @JsonKey(name: 'odometer_out_km')
  final int? odometerOutKm;
  @JsonKey(name: 'departed_at')
  final DateTime departedAt;
  final String? note;

  Map<String, Object?> toJson() => _$RegisterDepartureRequestToJson(this);
}
